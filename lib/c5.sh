##
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

source .kusanagi
source $LIBDIR/image_versions

IMAGE=$([ $OPT_NGINX ] && echo $KUSANAGI_NGINX_IMAGE || ([ $OPT_HTTPD ] && echo $KUSANGI_HTTPD_IMAGE))
# create docker-compose.yml
env PROFILE=$PROFILE \
    HTTPD_IMAGE=$IMAGE \
    KUSANAGI_PHP_IMAGE=$KUSANAGI_PHP_IMAGE \
    CONFIG_IMAGE=$KUSANAGI_CONFIG_IMAGE \
    CERTBOT_IMAGE=$CERTBOT_IMAGE \
    HTTP_PORT=$HTTP_PORT \
    HTTP_TLS_PORT=$HTTP_TLS_PORT \
    DBLIB=$DBLIB \
	envsubst '$$PROFILE $$HTTPD_IMAGE
	$$KUSANAGI_PHP_IMAGE
	$$CONFIG_IMAGE $$CERTBOT_IMAGE
	$$HTTP_PORT $$HTTP_TLS_PORT $$DBLIB' \
	< <(cat $LIBDIR/templates/docker.template $LIBDIR/templates/config.template $LIBDIR/templates/php.template) > docker-compose.yml
if ! [ $NO_USE_DB ] ; then
	case "$KUSANAGI_DB_SYSTEM" in
	mariadb)
		env PROFILE=$PROFILE KUSANAGI_MARIADB_IMAGE=$KUSANAGI_MARIADB_IMAGE \
		envsubst '$$PROFILE $$KUSANAGI_MARIADB_IMAGE' \
		< $LIBDIR/templates/mysql.template >> docker-compose.yml
		;;
	pgsql)
		env PROFILE=$PROFILE POSTGRESQL_IMAGE=$POSTGRESQL_IMAGE \
		envsubst '$$PROFILE $$POSTGRESQL_IMAGE' \
		< $LIBDIR/templates/pgsql.template >> docker-compose.yml
		;;
	esac

fi

echo >> docker-compose.yml
echo 'volumes:' >> docker-compose.yml
echo '  kusanagi:' >>  docker-compose.yml
[[ $DBHOST =~ ^localhost: ]] && echo '  database:' >> docker-compose.yml

docker-compose up -d \
&& k_configcmd_root "/" chown 1000:1001 /home/kusanagi \
&& k_configcmd "/" chmod 751 /home/kusanagi || return 1

k_print_green "$(eval_gettext 'Provision Concrete5')"

if [ "x$TARPATH" != "x" ] && [ -f $TARPATH ] ; then
	mkdir contents
	tar xf $TARPATH -C contents 
	tar cf - -C contents . | k_configcmd $BASEDIR tar xf - 
elif [  "x$GITPATH" != "x" ] && [ -f $GITPATH ] ; then 
	mkdir contents
	git clone $GITPATH ./contents
	tar cf - -C contents . | k_configcmd $BASEDIR tar xf - 
else
	docker-compose exec -u 1000 php /usr/local/bin/composer create-project -n concrete5/composer /home/kusanagi/$PROFILE \
	&& docker-compose exec -u 1000 php sh -c "grep -rl PhpSimple /home/kusanagi/$PROFILE/public |xargs -n 1 sed -i 's/Sunra/KubAT/g'" \
	&& docker-compose exec -u 1000 php sed -i 's/sunra/kub-at/g' /home/kusanagi/$PROFILE/public/concrete/composer.json \
	&& docker-compose exec -u 1000 php /usr/local/bin/composer remove -d /home/kusanagi/$PROFILE sunra/php-simple-html-dom-parser\
	&& docker-compose exec -u 1000 php /usr/local/bin/composer require -d /home/kusanagi/$PROFILE kub-at/php-simple-html-dom-parser\
	&& docker-compose exec -u 1000 php /usr/local/bin/composer update --with-dependencies -d /home/kusanagi/$PROFILE \ 
	&& k_configcmd_root /home/kusanagi chown -R 1000:1001 $PROFILE  \
	&& k_configcmd_root /home/kusanagi chmod o-rwx $PROFILE  \
	&& k_configcmd /home/kusanagi/$PROFILE/public mkdir -p application/languages \
	&& k_configcmd_root /home/kusanagi/$PROFILE/public chown -R 1001:1001 application/languages application/config application/files packages \
	&& k_configcmd_root /home/kusanagi/$PROFILE/public chmod -R g+w application/languages application/config application/files packages
fi

