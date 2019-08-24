##
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

source .kusanagi
source .kusanagi.wp
source $LIBDIR/image_versions

IMAGE=$([ $OPT_NGINX ] && echo $KUSANAGI_NGINX_IMAGE || ([ $OPT_HTTPD ] && echo $KUSANAGI_HTTPD_IMAGE))
# create docker-compose.yml
env FQDN=$FQDN \
    PROFILE=$PROFILE \
    HTTPD_IMAGE=$IMAGE \
    KUSANAGI_PHP_IMAGE=$KUSANAGI_PHP_IMAGE \
    CONFIG_IMAGE=$WPCLI_IMAGE \
    CERTBOT_IMAGE=$CERTBOT_IMAGE \
    HTTP_PORT=$HTTP_PORT \
    HTTP_TLS_PORT=$HTTP_TLS_PORT \
    DBLIB=$DBLIB \
	envsubst '$$FQDN $$PROFILE $$HTTPD_IMAGE
	$$KUSANAGI_PHP_IMAGE $$KUSANAGI_FTPD_IMAGE
	$$CONFIG_IMAGE $$CERTBOT_IMAGE
	$$HTTP_PORT $$HTTP_TLS_PORT $$DBLIB' \
	< <(cat $LIBDIR/templates/docker.template $LIBDIR/templates/wpcli.template $LIBDIR/templates/php.template) > docker-compose.yml
if ! [ $NO_USE_DB ] ; then
	env PROFILE=$PROFILE KUSANAGI_MYSQL_IMAGE=$KUSANAGI_MYSQL_IMAGE \
	envsubst '$$PROFILE $$KUSANAGI_MYSQL_IMAGE' \
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

mkdir -p wpcli
cat <<EOT > wpcli/Dockerfile
FROM $WPCLI_IMAGE 
MAINTAINER kusanagi@prime-strategy.co.jp

COPY wp_mysqli.ini /usr/local/etc/php/conf.d/wp_mysql.ini

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["wp", "shell"]
EOT
echo 'mysqli.default_socket = /var/run/mysqld/mysqld.sock' > wpcli/wp_mysqli.ini 

[[ $DBHOST =~ ^localhost ]] && echo '  database:' >> docker-compose.yml

function wp_lang() {
	if [ ${1} != "en_US" ] ; then
		k_configcmd $DOCUMENTROOT language core install ${WP_LANG} && \
		k_configcmd $DOCUMENTROOT language plugin install --all ${WP_LANG} && \
		k_configcmd $DOCUMENTROOT language theme install --all ${WP_LANG} && \
		k_configcmd $DOCUMENTROOT site switch-language ${WP_LANG} 
	fi
}

k_compose up -d \
&& k_configcmd_root "/" chown 1000:1001 /home/kusanagi  \
&& k_configcmd "/" chmod 751 /home/kusanagi \
&& k_configcmd "/" mkdir -p $DOCUMENTROOT || return 1

if [ "x$TARPATH" != "x" ] && [ -f $TARPATH ] ; then
	mkdir contents && \
	tar xf $TARPATH -C contents && \
	tar cf - -C contents . | k_configcmd $DOCUMENTROOT tar xf - 
elif [  "x$GITPATH" != "x" ] && [ -f $GITPATH ] ; then 
	mkdir contents && \
	git clone $GITPATH ./contents && \
	tar cf - -C contents . | k_configcmd $DOCUMENTROOT tar xf -
else

	if ! [ $NO_USE_DB ] ; then
		local ENTRY=1
		echo -n -e "\e[32m" $(eval_gettext "Waiting MySQL init process")
		while [ $ENTRY -eq 1 ] ; do
			echo -n "."
			sleep 5
			k_configcmd / mysqladmin status -u$DBUSER -p"$DBPASS" 2>&1 > /dev/null
			ENTRY=$?
		done
		echo -e "\e[m"
	fi

	k_print_green "$(eval_gettext 'Provision WordPress')"
	tar cf - -C $LIBDIR/wp/ tools settings wp-config-sample wp.sh | k_configcmd $BASEDIR tar xf - \
	&& k_configcmd $DOCUMENTROOT bash ../wp.sh \
	&& sleep 1 \
	&& k_configcmd $BASEDIR rm wp.sh \
	&& k_configcmd $DOCUMENTROOT chmod 440 wp-config.php \
	&& k_configcmd $DOCUMENTROOT mv wp-config.php .. \
	&& k_configcmd $DOCUMENTROOT mkdir -p ./wp-content/languages \
	&& k_configcmd $DOCUMENTROOT chmod 0750 . ./wp-content \
	&& k_configcmd $DOCUMENTROOT chmod -R 0770 ./wp-content/uploads \
	&& k_configcmd $DOCUMENTROOT chmod -R 0750 ./wp-content/languages ./wp-content/plugins \
	&& k_configcmd $DOCUMENTROOT sed -i "s/fqdn/$FQDN/g" ../tools/bcache.clear.php \
	&& tar cf - -C $LIBDIR/wp/ mu-plugins | k_configcmd $DOCUMENTROOT/wp-content tar xf - \
	|| return 1
fi

#if [ $OPT_WOO ] ; then
#	k_configcmd "" theme install storefront
#	docker cp $PROFILE_httpd $KUSANAGIDIR/lib/wp/wc4jp-gmo-pg.1.2.0.zip $PROFILE_httpd:$DOCUMENTROOT
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

