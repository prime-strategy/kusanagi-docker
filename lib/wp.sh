##
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

source .kusanagi
source .kusanagi.wp
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
	< <(cat $LIBDIR/templates/docker.template $LIBDIR/templates/wpcli.template) > docker-compose.yml
if [[ $DBHOST =~ ^localhost: ]] ; then
	env PROFILE=$PROFILE KUSANAGI_MARIADB_IMAGE=$KUSANAGI_MARIADB_IMAGE \
	envsubst '$$PROFILE $$KUSANAGI_MARIADB_IMAGE' \
	< $LIBDIR/templates/mysql.template >> docker-compose.yml
fi
if ! [ $NO_USE_FTP ] ; then
    env PROFILE=$PROFILE KUSANAGI_FTPD_IMAGE=$KUSANAGI_FTPD_IMAGE  \
	envsubst '$$PROFILE $$KUSANAGI_FTPD_IMAGE' \
	< $LIBDIR/templates/ftpd.template >> docker-compose.yml
fi
echo >> docker-compose.yml
echo 'volumes:' >> docker-compose.yml
echo '  kusanagi:' >>  docker-compose.yml
[[ $DBHOST =~ ^localhost: ]] && echo '  database:' >> docker-compose.yml


docker-compose up -d \
&& $CONFIGCMD chmod 751 /home/kusanagi \
&& $CONFIGCMD mkdir -p $DOCUMENTROOT || return 1
if [ "x$TARPATH" != "x" -a -f $TARPATH ] ; then
	:
elif [  "x$GITPATH" != "x" -a-f $GITPATH ] ; then 
	:
else

	$CONFIGCMD core download --path=${DOCUMENTROOT} ${WP_LANG:+ --locale=$WP_LANG} \
	&& $CONFIGCMD core config --path=${DOCUMENTROOT} \
		--dbname=${DBNAME} --dbuser=${DBUSER} --dbpass=${DBPASS} \
		${DBPREFIX:+--dbprefix $DBPREFIX} \
		--dbcharset=${MYSQL_CHARSET:-utf8mb4} --extra-php < $LIBDIR/wp/wp-config-extra.php \
	&& $CONFIGCMD core install --path=$DOCUMENTROOT --url=http://${FQDN} \
		--title=${WP_TITLE} --admin_user=${ADMIN_USER} \
		--admin_password=${ADMIN_PASSWORD} --admin_email=${ADMIN_EMAIL} \
	&& $CONFIGCMD chmod 440 $DOCUMENTROOT/wp-config.php \
	&& $CONFIGCMD mv $DOCUMENTROOT/wp-config.php $BASEDIR \
	&& tar cf - -C $LIBDIR/wp mu-plugins | $CONFIGCMD tar xf - -C $DOCUMENTROOT/wp-content/ \
	&& tar cf - -C $LIBDIR/wp tools settings | $CONFIGCMD tar xf - -C $DOCUMENTROOT/ \
	&& $CONFIGCMD mkdir -p $DOCUMENTROOT/wp-content/languages \
	&& $CONFIGCMD chmod 0750 $DOCUMENTROOT $DOCUMENTROOT/wp-content
	&& $CONFIGCMD chmod 0770 $DOCUMENTROOT/wp-content/uploads \
	&& $CONFIGCMD chmod -R 0770 $DOCUMENTROOT $DOCUMENTROOT/wp-content/languages $DOCUMENTROOT/wp-content/plugins \
	&& $CONFIGCMD sed -i "s/fqdn/$FQDN/g" $DOCUMENTROOT/tools/bcache.clear.php \
|| return 1
fi

#if [ $OPT_WOO ] ; then
#	$CONFIGCMD theme install storefront
#	docker cp $PROFILE_httpd $KUSANAGILIBDIR/wp/wc4jp-gmo-pg.1.2.0.zip $PROFILE_httpd:$DOCUMENTROOT
#	$CONFIGCMD unzip -q -d $DOCUMENTROOT/wp-content/plugins $DOCUMENTROOT/wc4jp-gmo-pg.1.2.0.zip
#	$CONFIGCMD rm $DOCUMENTROOT/wc4jp-gmo-pg.1.2.0.zip
#	if [ "WPLANG" = "ja" ] ; then
#		$CONFIGCMD plugin install woocommerce-for-japan
#		$CONFIGCMD language plugin install woocommerce-for-japan ja
#		$CONFIGCMD language theme install storefront ja
#		$CONFIGCMD plugin activate woocommerce-for-japan
#	fi
#	$CONFIGCMD theme activate storefront
#	$CONFIGCMD plugin activate wc4jp-gmo-pg
#
#fi

