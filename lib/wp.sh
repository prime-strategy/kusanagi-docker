##
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

source .kusanagi
# create docker-compose.yml
env PROFILE=$PROFILE NOUSE_FTP=${NOUSE_FTP:+#} NOUSE_DB=${NOUSE_DB:+#} \
	envsubst "$$PROFILE $$NOUSE_FTP $$NOUSE_DB" \
	< $LIBDIR/wp/docker.template > docker-compose.yml

docker-compose up -d \
&& docker-compose run wpcli mkdir -p $DOCUMENTROOT \
&& docker-compose run wpcli core download --path=${DOCUMENTROOT} \
	${WP_LANG:+ --locale=$WP_LANG} \
&& docker-compose run wpcli core config --path=${DOCUMENTROOT} \
	--dbname=${DBNAME} --dbuser=${DBUSER} --dbpass=${DBPASS} \
	${DBPREFIX:+--dbprefix $DBPREFIX} \
	--dbcharset=${MYSQL_CHARSET:-utf8mb4} --extra-php < $LIBDIR/wp/wp-config-extra.php \
&& docker-compose run wpcli core install --path=$DOCUMENTROOT --url=http://${FQDN} \
	--title=${WP_TITLE} --admin_user=${ADMIN_USER} \
	--admin_password=${ADMIN_PASSWORD} --admin_email=${ADMIN_EMAIL} \
&& tar cf - -C $LIBDIR/wp mu-plugins | docker-compose run wpcli tar xf - -C $DOCUMENTROOT/wp-content/ \
&& tar cf - -C $LIBDIR/wp tools settings | docker-compose run wpcli tar xf - -C $DOCUMENTROOT/ \
&& docker-compose run wpcli mkdir -p $DOCUMENTROOT/wp-content/languages \
&& docker-compose run wpcli chmod 0777 $DOCUMENTROOT $DOCUMENTROOT/wp-content $DOCUMENTROOT/wp-content/uploads \
&& docker-compose run wpcli chmod -R 0777 $DOCUMENTROOT $DOCUMENTROOT/wp-content/languages $DOCUMENTROOT/wp-content/plugins \
&& docker-compose run wpcli sed -i "s/fqdn/$FQDN/g" $DOCUMENTROOT/tools/bcache.clear.php \
&& docker exec -it -u0 ${PROFILE}_php7 chown -R 1000:1000 $DOCUMENTROOT 

