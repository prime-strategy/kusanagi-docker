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
	shift
	for OPT in "$@"
	do
		# skip 1st argment "provision"
		if [ $OPT_CERT ] ; then
			CERT=$(k_check_file "$PRE_OPT" "$OPT")
			[ -z $CERT ] && return 1
			OPT_CERT=
		elif [ $OPT_KEY ] ; then
			KEY=$(k_check_file "$PRE_OPT" "$OPT")
			[ -z $KEY ] && return 1
			OPT_KEY=
		elif [ $OPT_EMAIL ] ; then
			EMAIL=$(k_check_email "$PRE_OPT" "$OPT")
			[ -z $EMAIL ] && return 1
			OPT_EMAIL=
		elif [ $OPT_HSTS ] ; then
			HTTP_HSTS=$(k_check_onoff "$PRE_OPT" "$OPT")
			[ -z $HSTS ] && return 1
			OPT_HSTS=
		elif [ $OPT_OSCP ] ; then
			HTTP_OSCP=$(k_check_onoff "$PRE_OPT" "$OPT")
			[ -z $HTTP_TLS_PORT ] && return 1
			OPT_OSCP=
		elif [ $OPT_CT ] ; then
			CT=$(k_check_onoff "$PRE_OPT" "$OPT")
			[ -z $CT ] && return 1
			OPT_CT=
		else
			case "${OPT}" in
			'--cert')
				OPT_CERT=1
				;;
			--cert=*)
				CERT=$(k_check_file "${OPT%%=*}" "${OPT#*=}")
				[ -z $CERT ] && return 1
				;;
			'--key')
				OPT_KEY=1
				;;
			--key=*)
				KEY=$(k_check_file "${OPT%%=*}" "${OPT#*=}")
				[ -z $KEY ] && return 1
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
				[ -z $EMAIL ] && return 1
				;;
			'--hsts')
				OPT_HSTS=1
				;;
			--hsts=*)
				HSTS=$(k_check_onoff "${OPT%%=*}" "${OPT#*=}")
				[ -z $HSTS ] && return 1
				;;
			'--oscp')
				OPT_OSCP=1
				;;
			--oscp=*)
				OSCP=$(k_check_onoff "${OPT%%=*}" "${OPT#*=}")
				[ -z $HSTS ] && return 1
				;;
			'--ct')
				OPT_CT=1
				;;
			--ct=*)
				CT=$(k_check_onoff "${OPT%%=*}" "${OPT#*=}")
				[ -z $HSTS ] && return 1
				;;
			'--renew')
				OPT_RENEW=1
				;;
			-*)	# skip other option
				k_print_error $(eval_gettext "Cannot use option") $OPT
				return 1
				;;
			*)
				PROFILE="$OPT"
				break			# enable 1st (no option) string
			esac
		fi
		PRE_OPT=$OPT
	done

	# error check
	if [ "x$CERT$KEY" != "x" ] &&  [ "x$CERT" = "x" -o "x$KEY" = "x" ] ; then
		k_print_error "--cert and --key $(eval_gettext 'specified in same time.')"
		return 1
	elif [ "x$CERT" != "x" -o "x$KEY" != "x" -o "x$EMAIL" != "x" ] ; then
		k_print_error "--cert/--key and --ssl/email $(eval_gettext 'can not specified in same time.')"
	fi

	k_target $PROFILE
	k_machine > /dev/null
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.httpd
	if [ "x$EMAIL" != "x" ] ; then
		docker-compose run --rm certbot certonly --text --noninteractive --webroot -w /var/www/html -d $FQDN -m $EMAIL --agree-tos
		docer-compse run --rm -e RENEWD_LINAGE=/etc/letsencrypt/live/$FQDN httpd /usr/bin/ct-submit.sh
		SSL_CERT=/etc/letsencrypt/live/$FQDN/fullchain.pem
		SSL_KEY=/etc/letsencrypt/live/$FQDN/privkey.pem
	elif [ "x$CERT$KEY" != "x" ] ; then
		SSL_CERT=$(cat $CERT)
		SSL_KEY=$(cat $KEY)
	elif [ $OPT_RENEW ] ; then
		docker-compose run --rm certbot certonly --text --noninteractive --webroot -w /var/www/html -d $FQDN -m $EMAIL --agree-tos
		docer-compse run --rm -e RENEWD_LINAGE=/etc/letsencrypt/live/$FQDN httpd /usr/bin/ct-submit.sh
	fi
	FQDN=$FQDN
	DONOT_USE_FCACHE=$DONOT_USE_FCACHE
	if [ "$HSTS" = "on" ] ; then
		NO_USE_SSLST=0
	else
		NO_USE_SSLST=1
	fi
	if [ $OPT_REDIRECT -a $NO_SSL_REDIRECT ] ; then
		NO_SSL_REDIRECT=0
		if [ $KUSANAGI_PROVISION = "wp" ] ; then
			WPCONFIG=$(k_wpconfig)
			k_configcmd $WPCONFIG sed -i  "s/^[#\s]\+define('FORCE_SSL_ADMIN/define('FORCE_SSL_ADMIN/g" wp-config.php
			k_configcmd $DOCUMENTROOT search-replace http://$FQDN https://$FQDN --all-tables
		fi
	elif ! [ $OPT_REDIRECT -a $NO_SSL_REDIRECT ] ; then
		NO_SSL_REDIRECT=1
		if [ $KUSANAGI_PROVISION = "wp" ] ; then
			WPCONFIG=$(k_wpconfig)
			k_configcmd $WPCONFIG sed -i  "s/^\s\+define('FORCE_SSL_ADMIN/#define('FORCE_SSL_ADMIN/g" wp-config.php
			k_configcmd $DOCUMENTROOT search-replace https://$FQDN http://$FQDN --all-tables
		fi
	fi
	USE_SSL_CT=${CT:-off}
	USE_SSL_OSCP=${OSCP:-off}
	cat <<EOF > $TARGETDIR/.kusanagi.httpd
FQDN=$FQDN
DONOT_USE_FCACHE=$DONOT_USE_FCACHE
DONOT_USE_NAXSI=$DONOT_USE_NAXSI
NO_USE_SSLST=$NO_USE_SSLST
NO_SSL_REDIRECT=$NO_USE_REDIRECT
USE_SSL_CT=$USE_SSL_CT
USE_SSL_OSCP=$USE_SSL_OSCP
EOF
	docker-compose up -d httpd
}

