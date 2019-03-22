##
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

source .kusanagi
source .kusanagi.db
source $LIBDIR/.version

IMAGE=$([ $OPT_NGINX ] && echo $KUSANAGI_NGINX_IMAGE || ([ $OPT_HTTPD ] && echo $KUSANGI_HTTPD_IMAGE))
# create docker-compose.yml
env PROFILE=$PROFILE \
    HTTPD_IMAGE=$IMAGE \
    KUSANAGI_PHP7_IMAGE=$KUSANAGI_PHP7_IMAGE \
    CONFIG_IMAGE=$WPCLI_IMAGE \
    CERTBOT_IMAGE=$CERTBOT_IMAGE \
    HTTP_PORT=$HTTP_PORT \
    HTTP_TLS_PORT=$HTTP_TLS_PORT \
	envsubst '$$PROFILE $$HTTPD_IMAGE
	$$KUSANAGI_PHP7_IMAGE $$KUSANAGI_FTPD_IMAGE
	$$CONFIG_IMAGE $$CERTBOT_IMAGE
	$$HTTP_PORT $$HTTP_TLS_PORT' \
	< <(cat $LIBDIR/templates/docker.template $LIBDIR/templates/wpcli.template $LIBDIR/templates/php.template) > docker-compose.yml
if ! [ $NO_USE_DB ] ; then
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

k_print_green "$(eval_gettext 'Provision Concrete5')"
docker-compose up -d \
&& docker-compose run -u0 --rm config chown 1000:1001 /home/kusanagi  \
&& k_configcmd "/" chmod 751 /home/kusanagi || return 1

if [ "x$TARPATH" != "x" ] && [ -f $TARPATH ] ; then
	mkdir contents
	tar xf $TARPATH -C contents 
	tar cf - -C contents . | k_configcmd $DOCUMENTROOT tar xf - 
elif [  "x$GITPATH" != "x" ] && [ -f $GITPATH ] ; then 
	mkdir contents
	git clone $GITPATH ./contents
	tar cf - -C contents . | k_configcmd $DOCUMENTROOT tar xf - 
else
	docker-compose exec php -w /home/kusanagi \
		/usr/local/bin/composer create-project -n concrete5/composer $PROFILE \
	&& docker-compose run -u0 --rm -w /home/kusanagi config chown -R 1000:1001 $PROFILE  \
	&& docker-compose run -u0 --rm -w /home/kusanagi config chmod o-rwx $PROFILE  \
	&& k_configcmd /home/kusanagi/$PROFILE/public mkdir -p application/languages \
	&& docker-compose run -u0 --rm -w /home/kusanagi/$PROFILE/public config \
		chown -R 1001:1001 application/languages application/config application/files packages \
	&& docker-compose run -u0 --rm -w /home/kusanagi/$PROFILE/public config \
		chmod -R g+w application/languages application/config application/files packages \
fi
