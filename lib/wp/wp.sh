#
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

WP='php -d memory_limit=256M /usr/local/bin/wp'
wp_lang() {
	if [ ${1} != "en_US" ] ; then
		$WP language core install ${WP_LANG} && \
		$WP language plugin install --all ${WP_LANG} && \
		$WP language theme install --all ${WP_LANG} && \
		$WP site switch-language ${WP_LANG}
	fi
}

EXTRAPHP=$BASEDIR/wp-config-sample/$WP_LANG/wp-config-extra.php
[ -f $EXTRAPHP ] || EXTRAPHP=$BASEDIR/wp-config-sample/en_US/wp-config-extra.php
php -d memory_limit=256M /usr/local/bin/wp core download \
&& sleep 1 \
&& $WP core config \
	--dbhost=${DBHOST} \
	--dbname="${DBNAME}" --dbuser="${DBUSER}" --dbpass="${DBPASS}" \
	${DBPREFIX:+--dbprefix $DBPREFIX} \
	--dbcharset=${MYSQL_CHARSET:-utf8mb4} --extra-php < $EXTRAPHP \
&& sleep 1 \
&& $WP core install --url=http://${FQDN} \
	--title="${WP_TITLE}" --admin_user="${ADMIN_USER}" \
	--admin_password="${ADMIN_PASSWORD}" --admin_email="${ADMIN_EMAIL}" \
&& wp_lang $WP_LANG \
|| exit 1

#if [ $OPT_WOO ] ; then
#	k_configcmd "" theme install storefront
#	docker cp $PROFILE_httpd $KUSANAGILIBDIR/wp/wc4jp-gmo-pg.1.2.0.zip $PROFILE_httpd:$DOCUMENTROOT
#	k_configcmd "" unzip -q -d $DOCUMENTROOT/wp-content/plugins $DOCUMENTROOT/wc4jp-gmo-pg.1.2.0.zip
#	k_configcmd "" rm $DOCUMENTROOT/wc4jp-gmo-pg.1.2.0.zip
#	if [[ WP_LANG =~ ja ]] ; then
#		k_configcmd "" plugin install woocommerce-for-japan
#		k_configcmd "" language plugin install woocommerce-for-japan ja
#		k_configcmd "" language theme install storefront ja
#		k_configcmd "" plugin activate woocommerce-for-japan
#	fi
#	k_configcmd "" theme activate storefront
#	k_configcmd "" plugin activate wc4jp-gmo-pg
#
#fi

