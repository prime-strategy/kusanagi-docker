##
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

source .kusanagi

IMAGE=$([ $OPT_NGINX ] && echo $KUSANAGI_NGINX_IMAGE || ([ $OPT_HTTPD ] && echo $KUSANAGI_HTTPD_IMAGE))
# create docker-compose.yml
env FQDN=$FQDN \
	PROFILE=$PROFILE \
	HTTPD_IMAGE=$IMAGE \
	KUSANAGI_PHP_IMAGE=$KUSANAGI_PHP_IMAGE \
	CONFIG_IMAGE=$KUSANAGI_CONFIG_IMAGE \
	CERTBOT_IMAGE=$CERTBOT_IMAGE \
	HTTP_PORT=$HTTP_PORT \
	HTTP_TLS_PORT=$HTTP_TLS_PORT \
	DBLIB="$DBLIB" \
	envsubst '$$FQDN $$PROFILE $$HTTPD_IMAGE
	$$KUSANAGI_PHP_IMAGE
	$$CONFIG_IMAGE $$CERTBOT_IMAGE
	$$HTTP_PORT $$HTTP_TLS_PORT $$DBLIB' \
	< <(cat $LIBDIR/templates/docker.template $LIBDIR/templates/config.template $LIBDIR/templates/php.template) | \
	egrep -v '^\s*$' >> docker-compose.yml

if ! [[ $NO_USE_DB ]] ; then
	case "${KUSANAGI_DB_SYSTEM,,}" in
	mariadb)
		env PROFILE=$PROFILE KUSANAGI_MYSQL_IMAGE=$KUSANAGI_MYSQL_IMAGE \
		envsubst '$$PROFILE $$KUSANAGI_MYSQL_IMAGE' \
		< $LIBDIR/templates/mysql.template >> docker-compose.yml
		;;
	postgresql)
		env PROFILE=$PROFILE POSTGRESQL_IMAGE=$POSTGRESQL_IMAGE \
		envsubst '$$PROFILE $$POSTGRESQL_IMAGE' \
		< $LIBDIR/templates/pgsql.template >> docker-compose.yml
		;;
	*)
		exit 1
	esac
fi

echo >> docker-compose.yml
echo 'volumes:' >> docker-compose.yml
echo '  kusanagi:' >>  docker-compose.yml
[[ $NO_USE_DB ]] || echo '  database:' >> docker-compose.yml

k_compose up -d \
&& k_configcmd_root "/" chown 1000:1001 /home/kusanagi \
&& k_configcmd "/" chmod 751 /home/kusanagi || return 1

if [[ $NO_USE_DB ]] && ! k_db_check; then
	# error exit
	k_print_error "$KUSANAGI_DB_SYSTEM($DBHOST) $(eval_gettext "could not connect to.")"
	k_remove $PROFILE
	exit 1
fi

if [ "x$TARPATH" != "x" ] && [ -f $TARPATH ] ; then
	mkdir contents
	tar xf $TARPATH -C contents 
	k_copy $DOCUMENTROOT contents/* contents/.[^.]*
elif [  "x$GITPATH" != "x" ] && [ -f $GITPATH ] ; then 
	mkdir contents
	git clone $GITPATH ./contents
	k_copy $DOCUMENTROOT contents/* contents/.[^.]*
else
	## doctrine/orm 2.14.0 暫定対応
	k_compose exec -u 0 php apk add git patch \
	&& k_php_exec /home/kusanagi /usr/local/bin/composer -n create-project concrete5/composer --no-install $PROFILE \
	&& k_php_exec $BASEDIR /usr/local/bin/composer config --no-plugins allow-plugins.composer/installers true \
	&& k_php_exec $BASEDIR /usr/local/bin/composer config --no-plugins allow-plugins.mlocati/composer-patcher true \
	&& k_php_exec $BASEDIR /usr/local/bin/composer -n install \
	&& k_configcmd_root $BASEDIR sed -i 's/MappedSuperClass/MappedSuperclass/' \
			public/concrete/src/Entity/Page/Relation/Relation.php \
			public/concrete/src/Entity/Search/SavedSearch.php \
			public/concrete/src/Entity/Attribute/Key/Settings/Settings.php \
			public/concrete/src/Entity/Attribute/Value/Value/AbstractValue.php \
			public/concrete/src/Entity/Attribute/Value/AbstractValue.php \
	&& k_configcmd_root $BASEDIR sed -i "s/AnnotationRegistry::registerFile.*/AnnotationRegistry::registerLoader('class_exists');/" \
			public/concrete/src/Database/EntityManagerConfigFactory.php \
	&& k_configcmd_root $BASEDIR chown -R 1000:1001 . \
	&& k_configcmd /home/kusanagi chmod o-rwx $PROFILE  \
	&& k_configcmd $DOCUMENTROOT mkdir -p application/languages \
	&& k_configcmd_root $DOCUMENTROOT chown -R 1001:1001 application/languages application/config application/files packages \
	&& k_configcmd_root $DOCUMENTROOT chmod -R g+w application/languages application/config application/files packages
fi

k_print_green "$(eval_gettext 'Provision Concrete5')"

