##
# KUSANAGI WordPres Deployment for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

source .kusanagi
source .kusanagi.wp

_wpini=".wp_mysqli.ini"
if [[ $NO_USE_DB ]] ; then
	echo "mysqli.default_host = $DBHOST" >  $_wpini
	echo "mysqli.default_port = $DBPORT" >> $_wpini
	echo "mysqli.default_name = $DBNAME" >> $_wpini
	echo "mysqli.default_user = $DBUSER" >> $_wpini
	echo "mysqli.default_pw   = $DBPASS" >> $_wpini
else
	echo 'mysqli.default_socket = /var/run/mysqld/mysqld.sock' > $_wpini
fi

WSL1_BUILD=
WSL1_CONTEXTS=
WSL_INI=
WSL_VOL=
if [[ ! $NO_USE_DB ]] ; then
	WSL_VOL="- database:/var/run/mysqld"
fi
if (df . | awk 'END { print $1}' | grep / > /dev/null) ; then
	# WSL1以外
	WSL1_BUILD="    image: $WPCLI_IMAGE"
	WSL_INI="- ./.wp_mysqli.ini:/usr/local/etc/php/conf.d/wp_mysqli.ini"
else
	# WSL1
	WSL1_BUILD="    build:"
	WSL1_CONTEXTS="        context: ./wpcli"
	mkdir -p wpcli
cat <<EOT > wpcli/Dockerfile
FROM $WPCLI_IMAGE
MAINTAINER kusanagi@prime-strategy.co.jp

COPY .wp_mysqli.ini /usr/local/etc/php/conf.d/wp_mysql.ini

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["wp", "shell"]
EOT
fi

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
	WSL1_BUILD="$WSL1_BUILD" \
	WSL1_CONTEXT="$WSL1_CONTEXTS" \
	WSL_INI="$WSL_INI" \
	WSL_VOL="$WSL_VOL" \
	envsubst '$$FQDN $$PROFILE $$HTTPD_IMAGE
	$$KUSANAGI_PHP_IMAGE $$KUSANAGI_FTPD_IMAGE
	$$CONFIG_IMAGE $$CERTBOT_IMAGE
	$$HTTP_PORT $$HTTP_TLS_PORT $$DBLIB
	$$PROFILE $$WSL1_BUILD $$WSL1_CONTEXTS $$WSL_INI $$WSL_VOL' \
	< <(cat $LIBDIR/templates/docker.template $LIBDIR/templates/wpcli.template $LIBDIR/templates/php.template) | \
	egrep -v '^\s*$' > docker-compose.yml

if [[ $NO_USE_DB -eq 0 ]] ; then
	env PROFILE=$PROFILE KUSANAGI_MYSQL_IMAGE=$KUSANAGI_MYSQL_IMAGE \
	envsubst '$$PROFILE $$KUSANAGI_MYSQL_IMAGE' \
	< $LIBDIR/templates/mysql.template >> docker-compose.yml
fi
if [[ $NO_USE_FTP -eq 0 ]] ; then
	env PROFILE=$PROFILE KUSANAGI_FTPD_IMAGE=$KUSANAGI_FTPD_IMAGE  \
	envsubst '$$PROFILE $$KUSANAGI_FTPD_IMAGE' \
	< $LIBDIR/templates/ftpd.template >> docker-compose.yml
fi
echo >> docker-compose.yml
echo 'volumes:' >> docker-compose.yml
echo '  kusanagi:' >>  docker-compose.yml
[[ $NO_USE_DB ]] || echo '  database:' >> docker-compose.yml

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
	k_copy $DOCUMENTROOT contents/* contents/.[^.]*
elif [  "x$GITPATH" != "x" ] && [ -f $GITPATH ] ; then
	mkdir contents && \
	git clone $GITPATH ./contents && \
	k_copy $DOCUMENTROOT contents/* contents/.[^.]*
else
	if [[ $NO_USE_DB ]] ; then
		if ! k_mariadb_check; then
			# error exit
			k_print_error "MariaDB($DBHOST) $(eval_gettext "could not connect to.")"
			k_remove $PROFILE
			exit 1
		fi
	else
		echo -n -e "\e[32m" $(eval_gettext "Waiting MySQL init process")
		while ! k_mariadb_check; do
			echo -n "."
			sleep 5
		done
		echo -e "\e[m"
	fi

	k_copy $BASEDIR $LIBDIR/wp/tools $LIBDIR/wp/settings $LIBDIR/wp/wp-config-sample $LIBDIR/wp/wp.sh \
	&& k_configcmd $DOCUMENTROOT bash ../wp.sh \
	&& k_copy $DOCUMENTROOT/wp-content $LIBDIR/wp/mu-plugins \
	&& sleep 1 \
	&& k_configcmd_root "/" chown -R 1000:1001 /home/kusanagi  \
	&& k_configcmd $BASEDIR rm wp.sh \
	&& k_configcmd $DOCUMENTROOT chmod 440 wp-config.php \
	&& k_configcmd $DOCUMENTROOT mv wp-config.php .. \
	&& k_configcmd $DOCUMENTROOT mkdir -p ./wp-content/languages \
	&& k_configcmd $DOCUMENTROOT chmod 0750 . ./wp-content \
	&& k_configcmd $DOCUMENTROOT chmod -R 0770 ./wp-content/uploads \
	&& k_configcmd $DOCUMENTROOT chmod -R 0750 ./wp-content/languages ./wp-content/plugins \
	&& k_configcmd $DOCUMENTROOT sed -i "s/fqdn/$FQDN/g" ../tools/bcache.clear.php \
	|| return 1
fi

k_print_green "$(eval_gettext 'Provision WordPress')"
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

