#!/bin/sh

#//---------------------------------------------------------------------------
#// create self-signed cert
#//---------------------------------------------------------------------------
if [ -f /etc/pki/tls/private/localhost.key -o -f /etc/pki/tls/certs/localhost.crt ]; then
	/bin/true
else
	/usr/bin/openssl genrsa -rand /proc/apm:/proc/cpuinfo:/proc/dma:/proc/filesystems:/proc/interrupts:/proc/ioports:/proc/pci:/proc/rtc:/proc/uptime 2048 > /etc/pki/tls/private/localhost.key 2> /dev/null

	cat <<-EOF | /usr/bin/openssl req -new -key /etc/pki/tls/private/localhost.key \
		-x509 -sha256 -days 365 -set_serial $RANDOM -extensions v3_req \
		-out /etc/pki/tls/certs/localhost.crt 2>/dev/null
--
SomeState
SomeCity
SomeOrganization
SomeOrganizationalUnit
${FQDN}
root@${FQDN}
	EOF
fi

#//---------------------------------------------------------------------------
#// create nginx/httpd conf
#//---------------------------------------------------------------------------
if [ ! -e /etc/nginx/conf.d/${PROFILE}_http.conf ]; then
	
	. /usr/lib/kusanagi/lib/functions.sh
	sh -x /usr/lib/kusanagi/lib/virt.sh
	if [ -n "$PROFILE" ]; then
	    echo 'PROFILE="'$PROFILE'"' > /etc/kusanagi.conf
	fi

	for i in \
		/etc/nginx/conf.d/${PROFILE}_*.conf \
		/etc/httpd/conf.d/${PROFILE}_*.conf \
		;
	do
		sed -i 's/127.0.0.1:9000/php:9000/' $i;
	done
fi

#//---------------------------------------------------------------------------
#// Improv security
#//---------------------------------------------------------------------------
# Improv Sec
if [ ! -d /etc/kusanagi.d/ssl ] ; then
	mkdir -p /etc/kusanagi.d/ssl
fi
if [ ! -e /etc/kusanagi.d/ssl/ssl_sess_ticket.key ] ; then
	openssl rand 48 > /etc/kusanagi.d/ssl_sess_ticket.key
fi
if [ ! -e /etc/kusanagi.d/ssl/dhparam.key ] ; then
	openssl dhparam 2048 -out /etc/kusanagi.d/ssl/dhparam.key
fi

#//---------------------------------------------------------------------------
#// backend/frontend cache
#//---------------------------------------------------------------------------
WPCONFIG="/home/kusanagi/${PROFILE}/DocumentRoot/wp-config.php"
WPCONFIG_SAMPLE="/home/kusanagi/${PROFILE}/DocumentRoot/wp-config-sample.php"

NGINX_HTTP="/etc/nginx/conf.d/${PROFILE}_http.conf"
NGINX_HTTPS="/etc/nginx/conf.d/${PROFILE}_ssl.conf"

#//-------------------------------------
#// backend cache
#//-------------------------------------
if [ "$BCACHE" = "on" ]; then
	if [ -e $WPCONFIG ]; then
		sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG
		sed -i "s/^\s*[#\/]\+\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG
	fi
	if [ -e $WPCONFIG_SAMPLE ]; then
		sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG_SAMPLE
		sed -i "s/^\s*[#\/]\+\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG_SAMPLE
	fi
else
	if [ -e $WPCONFIG ]; then
		sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/#define('WP_CACHE', true);/" $WPCONFIG
	fi
	if [ -e $WPCONFIG_SAMPLE ]; then
		sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/#define('WP_CACHE', true);/" $WPCONFIG_SAMPLE
	fi
fi

#//-------------------------------------
#// frontend cache
#//-------------------------------------
if [ "$FCACHE" = "on" ]; then
	if [ -e $NGINX_HTTP ]; then
		sed -i "s/set\s*\$do_not_cache\s*1\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 0; ## page cache/" $NGINX_HTTP
	fi
	if [ -e $NGINX_HTTPS ]; then
		sed -i "s/set\s*\$do_not_cache\s*1\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 0; ## page cache/" $NGINX_HTTPS
	fi
else
	if [ -e $NGINX_HTTP ]; then
		sed -i "s/set\s*\$do_not_cache\s*0\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 1; ## page cache/" $NGINX_HTTP
	fi
	if [ -e $NGINX_HTTPS ]; then
		sed -i "s/set\s*\$do_not_cache\s*0\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 1; ## page cache/" $NGINX_HTTPS
	fi
fi

#//---------------------------------------------------------------------------
#// execute nginx
#//---------------------------------------------------------------------------
exec "$@"
