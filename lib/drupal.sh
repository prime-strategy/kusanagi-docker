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
    DBLIB=$DBLIB \
	envsubst '$$FQDN $$PROFILE $$HTTPD_IMAGE
	$$KUSANAGI_PHP_IMAGE
	$$CONFIG_IMAGE $$CERTBOT_IMAGE
	$$HTTP_PORT $$HTTP_TLS_PORT $$DBLIB' \
	< <(cat $LIBDIR/templates/docker.template $LIBDIR/templates/config.template $LIBDIR/templates/php.template) | \
	egrep -v '^\s*$' > docker-compose.yml

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
	esac

fi
echo >> docker-compose.yml
echo 'volumes:' >> docker-compose.yml
echo '  kusanagi:' >>  docker-compose.yml
[[ $NO_USE_DB ]] || echo '  database:' >> docker-compose.yml


k_compose up -d \
&& k_configcmd_root "/" chown 1000:1001 /home/kusanagi \
&& k_configcmd "/" chmod 751 /home/kusanagi \
&& k_configcmd "/" mkdir -p $DOCUMENTROOT \
&& k_copy $BASEDIR $LIBDIR/drupal/drupal.sh

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
	k_php_exec $BASEDIR sh ./drupal.sh $DRUPAL_VERSION \
	&& sleep 1 \
	&& k_php_exec $BASEDIR rm ./drupal.sh
fi

k_print_green "$(eval_gettext 'Provision Drupal')"
