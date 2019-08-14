#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

function k_ssl () {
	local OPT_EMAIL OPT_CERT OPT_KEY OPT_REDIRECT=0
	local OPT_HSTS OPT_OSCP OPT_CT OPT_REGISTER
	local OPT PRE_OPT
	local EMAIL= CERT= KEY= HSTS= OSCP= CT= REGISTER= RENEW=
	local PROFILE=

	## perse arguments
	if [ "x$2" = "x" ] ; then
		k_print_error config $1 $(eval_gettext "is unknown subcommand.")
		return 1
	fi
	shift
	for OPT in "$@"
	do
		# skip 1st argment "provision"
		if [ $OPT_CERT ] ; then
			CERT=$(k_check_file "$PRE_OPT" "$OPT")
			[ "$OPT" != "$CERT" ] && return 1
			OPT_CERT=
		elif [ $OPT_KEY ] ; then
			KEY=$(k_check_file "$PRE_OPT" "$OPT")
			[ "$OPT" != "$KEY" ] && return 1
			OPT_KEY=
		elif [ $OPT_EMAIL ] ; then
			EMAIL=$(k_check_email "$PRE_OPT" "$OPT")
			[ "$OPT" != "$EMAIL" ] && return 1
			OPT_EMAIL=
		elif [ $OPT_HSTS ] ; then
			HSTS=$(k_check_onoff "$PRE_OPT" "$OPT")
			[ "$OPT" != "$HSTS" ] && return 1
			OPT_HSTS=
		elif [ $OPT_OSCP ] ; then
			OSCP=$(k_check_onoff "$PRE_OPT" "$OPT")
			[ "$OPT" != "$OSCP" ] && return 1
			OPT_OSCP=
		elif [ $OPT_CT ] ; then
			CT=$(k_check_onoff "$PRE_OPT" "$OPT")
			[ "$OPT" != "$CT" ] && return 1
			OPT_CT=
		else
			case "${OPT}" in
			'--cert')
				OPT_CERT=1
				;;
			--cert=*)
				CERT=$(k_check_file "${OPT%%=*}" "${OPT#*=}")
				[ "${OPT#*=}" != "$CERT" ] && return 1
				;;
			'--key')
				OPT_KEY=1
				;;
			--key=*)
				KEY=$(k_check_file "${OPT%%=*}" "${OPT#*=}")
				[ "${OPT#*=}" != "$KEY" ] && return 1
				;;
			'--redirect')
				OPT_REDIRECT=1
				;;
			'--noredirect'|'--no-redirect')
				OPT_REDIRECT=0
				;;
			'--email'|'--ssl')
				OPT_EMAIL=1
				;;
			--email=*|--ssl=*)
				EMAIL=$(k_check_email "${OPT%%=*}" "${OPT#*=}")
				[ "${OPT#*=}" != "$EMAIL" ] && return 1
				;;
			'--hsts')
				OPT_HSTS=1
				;;
			--hsts=*)
				HSTS=$(k_check_onoff "${OPT%%=*}" "${OPT#*=}")
				[ "${OPT#*=}" != "$HSTS" ] && return 1
				;;
			'--oscp')
				OPT_OSCP=1
				;;
			--oscp=*)
				OSCP=$(k_check_onoff "${OPT%%=*}" "${OPT#*=}")
				[ "${OPT#*=}" != "$OSCP" ] && return 1
				;;
			'--ct')
				OPT_CT=1
				;;
			--ct=*)
				CT=$(k_check_onoff "${OPT%%=*}" "${OPT#*=}")
				[ "${OPT#*=}" != "$CT" ] && return 1
				;;
			'--renew')
				OPT_RENEW=1
				;;
			'--help'|help)
				k_helphelp ssl help
				return 0
				;;
			*)	# skip other option
				k_print_error $(eval_gettext "Cannot use option") $OPT
				return 1
				;;
			esac
		fi
		PRE_OPT=$OPT
	done

	k_target $PROFILE
	#k_machine > /dev/null
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.httpd

	# error check
	if [ "x$CERT$KEY" != "x" ] && [ "x$CERT" = "x" -o "x$KEY" = "x" ] ; then
		k_print_error "--cert and --key $(eval_gettext 'specified in same time.')"
		return 1
	elif [ "x$CERT" != "x" -o "x$KEY" != "x" ] && [ "x$EMAIL" != "x" ] ; then
		k_print_error "--cert/--key and --ssl/email $(eval_gettext 'can not specified in same time.')"
	fi

	if [ "x$EMAIL" != "x" ] ; then
		k_compose run --rm certbot certonly --text --noninteractive --webroot -w /var/www/html -d $FQDN -m $EMAIL --agree-tos
		docer-compse run --rm -e RENEWD_LINAGE=/etc/letsencrypt/live/$FQDN httpd /usr/bin/ct-submit.sh
		SSL_CERT=/etc/letsencrypt/live/$FQDN/fullchain.pem
		SSL_KEY=/etc/letsencrypt/live/$FQDN/privkey.pem
	elif [ "x$CERT$KEY" != "x" ] ; then
		SSL_CERT=$(cat $CERT |tr "\r\n" " " | sed 's/  / /g')
		SSL_KEY=$(cat $KEY |tr "\r\n" " " | sed 's/  / /g')
	elif [ $OPT_RENEW ] ; then
		k_compose run --rm certbot certonly --text --noninteractive --webroot -w /var/www/html -d $FQDN -m $EMAIL --agree-tos
		k_compose run --rm -e RENEWD_LINAGE=/etc/letsencrypt/live/$FQDN httpd /usr/bin/ct-submit.sh
	fi
	FQDN=$FQDN
	NO_USE_FCACHE=$NO_USE_FCACHE
	if [ "$HSTS" = "on" -o $NO_USE_SSLST -eq 0 ] ; then
		NO_USE_SSLST=0
	else
		NO_USE_SSLST=1
	fi
	if [ $OPT_REDIRECT -eq 1 -a $NO_SSL_REDIRECT -eq 1 ] ; then
		NO_SSL_REDIRECT=0
		if [ $KUSANAGI_PROVISION = "wp" ] ; then
			WPCONFIG=$(k_wpconfig)
			k_configcmd $WPCONFIG chmod +w wp-config.php
			k_configcmd $WPCONFIG sed -i "s/^[#\s]\+define('FORCE_SSL_ADMIN/define('FORCE_SSL_ADMIN/g" wp-config.php
			k_configcmd $WPCONFIG chmod a-w wp-config.php
			k_configcmd $DOCUMENTROOT search-replace http://$FQDN https://$FQDN --all-tables > /dev/null
		fi
	elif [ $OPT_REDIRECT -eq 0 -a $NO_SSL_REDIRECT -eq 0 ] ; then
		NO_SSL_REDIRECT=1
		if [ $KUSANAGI_PROVISION = "wp" ] ; then
			WPCONFIG=$(k_wpconfig)
			k_configcmd $WPCONFIG chmod +w wp-config.php
			k_configcmd $WPCONFIG sed -i "s/^\s\+define('FORCE_SSL_ADMIN/#define('FORCE_SSL_ADMIN/g" wp-config.php
			k_configcmd $WPCONFIG chmod a-w wp-config.php
			k_configcmd $DOCUMENTROOT search-replace https://$FQDN http://$FQDN --all-tables > /dev/null
		fi
	fi
	[ "x$CT" != "x" ] && USE_SSL_CT=${CT}
	[ "x$OSCP" != "x" ] && USE_SSL_OSCP=${OSCP}
	cat <<EOF > $TARGETDIR/.kusanagi.httpd
FQDN=$FQDN
NO_USE_FCACHE=$NO_USE_FCACHE
USE_SSL_CT=$USE_SSL_CT
USE_SSL_OSCP=$USE_SSL_OSCP
EOF
	[ "SSL_DHPARAM" ] && echo SSL_DHPARAM=\"$SSL_DHPARAM\" >> $TARGETDIR/.kusanagi.httpd
	[ "$SSL_CERT" ] && echo SSL_CERT=\"$SSL_CERT\" >> $TARGETDIR/.kusanagi.httpd
	[ "$SSL_KEY" ] && echo SSL_KEY=\"$SSL_KEY\" >> $TARGETDIR/.kusanagi.httpd
	[ $NO_USE_SSLST -eq 1 ] && echo NO_USE_SSLST=$NO_USE_SSLST >> $TARGETDIR/.kusanagi.httpd
	[ $NO_SSL_REDIRECT -eq 1 ] && echo NO_SSL_REDIRECT=$NO_SSL_REDIRECT >> $TARGETDIR/.kusanagi.httpd
	[ $NO_USE_NAXSI -eq 1 ] && echo NO_USE_NAXSI=$NO_USE_NAXSI >> $TARGETDIR/.kusanagi.httpd

	k_compose up -d 
}

