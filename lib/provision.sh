##
# KUSANAGI provision for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

function k_check_wplang() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [ "$OPT" =  "en_US" -o "$OPT" = "ja" ] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input 'en_US' or 'ja'.")
	fi
}

function k_check_fqdn() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "$OPT" =~ ^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]))+\.?$ ]] && \
	       	[[ "$OPT" =~ ^[a-zA-Z0-9\.\-]{3,253}$ ]] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input valid hostname.")
	fi
}

function k_check_email() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "${OPT,,}" =~ ^[a-z0-9!$\&*.=^\`|~#%\'+\/?_{}-]+@([a-z0-9_-]+\.)+(xx--[a-z0-9]+|[a-z]{2,})$ ]] ; then #'`
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input valid email address.")
	fi
}
function k_check_port() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "$OPT" =~ ^[0-9]+ ]] && [ $OPT -gt 0 -a $OPT -lt 65536 ] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input valid port number.")
	fi
}

function k_check_host() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "$OPT" =~ ^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]))+\.?$ ]] && \
	       	[[ "$OPT" =~ ^[a-zA-Z0-9\.\-]{3,253}$ ]] ; then
		echo "$OPT"
	elif [[ "$OPT" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
		echo "$OPT"
	elif [[ "$OPT" =~ ^(([0-9A-Fa-f]{0,4}::?){1,7}[0-9A-Fa-f]{0,4})$ ]] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input valid hostname.")
	fi
}

function k_check_dbname() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,64}$ ]]; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input [a-zA-Z0-9._-] 3 to 64 characters.")
	fi
}

function k_check_dbuser() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,16}$ ]] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter username for database. USE [a-zA-Z0-9._-] 3 to 16 characters.")
	fi
}

function k_check_dbpass() {
	local PRE_OPT="$1"
	local OPT="$2"
	local USER="$3"
	if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter password for database user '\$USER'. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
	fi
}

function k_check_adminuser() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{4,}$ ]] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter admin username for WordPress. USE [a-zA-Z0-9._-] 4 characters minimum.")
	fi
}

function k_check_dbsystem() {
	local PRE_OPT="$1"
	local OPT="$2"
	local DB="$3"
	case "$OPT" in
	'mysql'|'mariadb')
		if [ "x$DB" = "x" ] ; then
			echo mariadb
		else
			k_print_notice $(eval_gettext "option:") $OPT: $(eval_gettext "can not be specified with another db system.")
		fi
		;;
	'postgresql'|'pgsql')
		if [ "x$DB" = "x" ] ; then
			echo pgsql
		else
			k_print_notice $(eval_gettext "option:") $OPT: $(eval_gettext "can not be specified with another db system.")
		fi
		;;
	'*')
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "can not be specified.")
	esac
}

function k_check_passwd() {
	local PRE_OPT="$1"
	local OPT="$2"
	local USER="$3"
	if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter \$USER password for WordPress. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
	fi
}

function k_check_title() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [[ "$OPT" =~ ^.{1,}$ ]] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter Title for for WordPress. USE 1 characters minimum.")
	fi
}

function k_provision () {
	local OPT_WOO=	# use WooCommerce option(1 = use/other no use)
	local OPT_WPLANG OPT_FQDN OPT_EMAIL OPT_DBHOST OPT_DBROOTPASS
	local OPT_DBNAME OPT_DBUSER OPT_DBPASS OPT_KUSANAGI_PASS OPT_DBSYSTEM
	local OPT_NGINX OPT_HTTPD OPT_HTTP_PORT OPT_TLS_PORT
	local OPT PRE_OPT
	local WPLANG=en_US FQDN= MAILADDR= DBHOST= DBROOTPASS= DBNAME= DBUSER= DBPASS=
	local ADMIN_USER= ADMIN_PASS= KUSANAGI_PASS= WP_TITLE= GITPATH= TARPATH=
	local OPT_NO_FTP= OPT_NO_EMAIL=1
	local HTTP_PORT=80 HTTP_TLS_PORT=443
	local KUSANAGI_DB_SYSTEM= USE_INTERNALDB=0
	local APP=
	## perse arguments
	shift
	for OPT in "$@"
	do
		# skip 1st argment "provision"
		if [ $OPT_WPLANG ] ; then
			WP_LANG=$(k_check_wplang "$PRE_OPT" "$OPT")
			[ -z $WP_LANG ] && return 1
			OPT_WPLANG=
		elif [ $OPT_FQDN ] ; then
			FQDN=$(k_check_fqdn "$PRE_OPT" "$OPT")
			[ -z $FQDN ] && return 1
			OPT_FQDN=
		elif [ $OPT_EMAIL ] ; then
			MAILADDR=$(k_check_email "$PRE_OPT" "$OPT")
			[ -z $MAILADDR ] && return 1
			OPT_EMAIL=
		elif [ $OPT_HTTP_PORT ] ; then
			HTTP_PORT=$(k_check_port "$PRE_OPT" "$OPT")
			[ -z $HTTP_PORT ] && return 1
			OPT_hTTP_PORT=
		elif [ $OPT_TLS_PORT ] ; then
			HTTP_TLS_PORT=$(k_check_port "$PRE_OPT" "$OPT")
			[ -z $HTTP_TLS_PORT ] && return 1
			OPT_TLS_PORT=
		elif [ $OPT_DBHOST ] ; then
			DBHOST=$(k_check_host "$PRE_OPT" "$OPT")
			[ -z $DBHOST ] && return 1
			OPT_DBHOST=
		elif [ $OPT_DBNAME ] ; then
			DBNAME=$(k_check_dbname "$PRE_OPT" "$OPT")
			[ -z $DBNAME ] && return 1
			OPT_DBNAME=
		elif [ $OPT_DBUSER ] ; then
			DBUSER=$(k_check_dbuser "$PRE_OPT" "$OPT")
			[ -z $DBUSER ] && return 1
			OPT_DBUSER=
		elif [ $OPT_DBPASS ] ; then
			DBPASS=$(k_check_dbpass "$PRE_OPT" "$OPT" DBUSER)
			[ -z $DBPASS ] && return 1
			OPT_DBPASS=
		elif [ $OPT_DBROOTPASS ] ; then
			DBROOTPASS=$(k_check_dbpass "$PRE_OPT" "$OPT" root)
			[ -z $DBROOTPASS ] && return 1
			OPT_DBROOTPASS=
		elif [ $OPT_ADMIN_USER ] ; then
			ADMIN_USER=$(k_check_adminuser "$PRE_OPT" "$OPT")
			[ -z $ADMIN_USER ] && return 1
			OPT_ADMIN_USER=
		elif [ $OPT_DBSYSTEM ] ; then
			KUSANAGI_DB_SYSTEM=$(k_check_dbsystem "$PRE_OPT" "$OPT" "$KUSANAGI_DB_SYSTEM")
			[ -z $KUSANAGI_DB_SYSTEM ] && return 1
			OPT_DBSYSTEM=
		elif [ $OPT_ADMIN_PASS ] ; then
			ADMIN_PASS=$(k_check_passwd "$PRE_OPT" "$OPT" admin)
			[ -z $ADMIN_PASS ] && return 1
			OPT_ADMIN_USER=
		elif [ $OPT_KUSANAGI_PASS ] ; then
			KUSANAGI_PASS=$(k_check_passwd "$PRE_OPT" "$OPT" kusanagi)
			[ -z $KUSANAGI_PASS ] && return 1
			OPT_KUSANAGI_USER=
		elif [ $OPT_WP_TITLE ] ; then
			WP_TITLE=$(k_check_title "$PRE_OPT" "$OPT")
			[ -z $WP_TITLE ] && return 1
			OPT_WP_TITLE=
		elif [ $OPT_GIT ] ; then
			GITPATH=$(k_check_path "$PRE_OPT" "$OPT")
			[ -z $GITPATH ] && return 1
			OPT_GIT=
		elif [ $OPT_TAR ] ; then
			TARPATH=$(k_check_path "$PRE_OPT" "$OPT")
			[ -z $TARPATH ] && return 1
			OPT_TAR=
		else
			case "${OPT}" in
			'--woo'|'--WooCommerce')
				export OPT_WOO=0
					k_print_notice $(eval_gettext "option:") $OPT: $(eval_gettext "not implimented.")
				;;
			'--wordpress'|'--WordPress')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='wp'
				;;
			'--c5'|'--concrete5')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='c5'
				;;
			'--lamp'|'--LAMP')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='lamp'
				;;
			'--drupal'|'--drupal8')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='drupal8'
				;;
			'--rails'|'--RubyonRails')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='rails';
				;;
			'--wplang')
				OPT_WPLANG=1
				;;
			--wplang=*)
				WP_LANG=$(k_check_wplang "${OPT%%=*}" "${OPT#*=}")
				[ -z $WP_LANG ] && return 1
				;;
			'--fqdn')
				OPT_FQDN=1
				;;
			--fqdn=*)
				FQDN=$(k_check_fqdn "${OPT%%=*}" "${OPT#*=}")
				[ -z $FQDN ] && return 1
				;;
			'--http-port')
				OPT_HTTP_PORT=1
				;;
			--http-port=*)
				HTTP_PORT=$(k_check_port "${OPT%%=*}" "${OPT#*=}")
				[ -z $HTTP_PORT ] && return 1
				;;
			'--tls-port'|'--https-port')
				OPT_TLS_PORT=1
				;;
			--tls-port=*|--http-port=*)
				HTTP_TLS_PORT=$(k_check_port "${OPT%%=*}" "${OPT#*=}")
				[ -z $HTTP_TLS_PORT ] && return 1
				;;
			'--email'|'--ssl')
				OPT_EMAIL=1
				OPT_NO_EMAIL=0
				;;
			--email=*|--ssl=*)
				MAILADDR=$(k_check_email "${OPT%%=*}" "${OPT#*=}")
				[ -z $MAILADDR ] && return 1
				OPT_NO_EMAIL=0
				;;
			'--dbhost')
				OPT_DBHOST=1
				;;
			--dbhost=*)
				DBHOST=$(k_check_host "${OPT%%=*}" "${OPT#*=}")
				[ -z $DBHOST ] && return 1
				;;
			'--dbrootpass')
				OPT_DBROOTPASS=1
				;;
			--dbrootpass=*)
				DBROOTPASS=$(k_check_dbpass "${OPT%%=*}" "${OPT#*=}" root)
				[ -z $DBUSER ] && return 1
				;;
			'--dbname')
				OPT_DBNAME=1
				;;
			--dbname=*)
				DBNAME=$(k_check_dbname "${OPT%%=*}" "${OPT#*=}")
				[ -z $DBNAME ] && return 1
				;;
			'--dbuser')
				OPT_DBUSER=1
				;;
			--dbuser=*)
				DBUSER=$(k_check_dbuser "${OPT%%=*}" "${OPT#*=}")
				[ -z $DBUSER ] && return 1
				;;
			'--dbpass')
				OPT_DBPASS=1
				;;
			--dbpass=*)
				DBPASS=$(k_check_dbpass "${OPT%%=*}" "${OPT#*=}" DBUSER)
				[ -z $DBPASS ] && return 1
				;;
			'--noftp'|'--no-ftp')
				OPT_NO_FTP=1
				;;
			'--nginx')
				OPT_NGINX=1
				;;
			'--httpd')
				OPT_HTTPD=1
				;;
			'--admin_user')
				OPT_ADMIN_USER=1
				;;
			--admin_user=*)
				ADMIN_USER=$(k_check_adminuser "${OPT%%=*}" "${OPT#*=}")
				[ -z $ADMIN_USER ] && return 1
				;;
			'--kusanagi-pass')
				OPT_KUSANAGI_PASS=1
				;;
			--kusanagi-pass=*)
				KUSANAGI_PASS=$(k_check_passwd "${OPT%%=*}" "${OPT#*=}" kusanagi)
				[ -z $KUSANAGI_PASS ] && return 1
				;;
			'--admin_pass')
				OPT_ADMIN_PASS=1
				;;
			--admin_pass=*)
				ADMIN_PASS=$(k_check_passwd "${OPT%%=*}" "${OPT#*=}" admin)
				[ -z $ADMIN_PASS ] && return 1
				;;
			'--wp-title')
				OPT_WP_TITLE=1
				;;
			--wp-title=*)
				WP_TITLE=$(k_check_title "${OPT%%=*}" "${OPT#*=}")
				[ -z $WP_TITLE ] && return 1
				;;
			'--git')
				OPT_GIT=1
				;;
			--git=*)
				GITPATH=$(k_check_path "${OPT%%=*}" "${OPT#*=}")
				[ -z $GITPATH ] && return 1
				;;
			'--tar'|'--tarball')
				OPT_TAR=1
				;;
			--tar=*|--tarball=*)
				TARPATH=$(k_check_path "${OPT%%=*}" "${OPT#*=}")
				[ -z $TARPATH ] && return 1
				;;
			'--dbsystem')
				OPT_DBSYSTEM=1
				;;
			--dbsystem=*)
				KUSANAGI_DB_SYSTEM=$(k_check_dbsystem "${OPT%%=*}" "${OPT#*=}" "$KUSANAGI_DB_SYSTEM")
				[ -z $KUSANAGI_DB_SYSTEM ] && return 1
				;;
			-*)	# skip other option
				k_print_error $(eval_gettext "Cannot use option") $OPT
				return 1
				;;
			*)
				NEW_PROFILE="$OPT"
				break			# enable 1st (no option) string
			esac
		fi
		PRE_OPT=$OPT
	done
	APP=${APP:-wp}
	KUSANAGI_DB_SYSTEM=${KUSANAGI_DB_SYSTEM:-mariadb}
	
	## option check
	if [ $OPT_NGINX -a $OPT_HTTPD ] ; then
		if [ "x$OPT_NGINX" = "x" ] ; then
			OPT_NGINX=1
		else
			k_print_error $(eval_gettext "option --nginx and --httpd is can not specify both at the same time.")
			return 1
		fi
	fi

	## check profile name and directory 
	if [[ ! $NEW_PROFILE =~ ^[a-zA-Z0-9._-]{3,24}$ ]]; then
		k_print_error $(eval_gettext "Target name requires [a-zA-Z0-9._-] 3-24 characters.")
		return 1
	fi
	
	# for config
	PROFILE=$NEW_PROFILE
	KUSANAGI_TYPE=$APP
	KUSANAGI_DIR=$(pwd)/$PROFILE
	
	## fqdn
	if [ -z "$FQDN" ]; then
		k_print_error $(eval_gettext "require option --fqdn for your website. ex) kusanagi.tokyo.")
		return false
	fi

	if [ "wp" = $APP ]; then
		WP_TITLE=${WP_TITLE:-WordPress}
		WPLANG=${WPLANG:-ja}
		## kusanagi user password
		KUSANAGI_PASS=${KUSANAGI_PASS:-$(k_mkpasswd)}
		# admin user
		ADMIN_USER=${ADMIN_USER:-$(k_mkusername)}
		# admin password
		ADMIN_PASS=${ADMIN_PASS:-$(k_mkpasswd)}
		# admin email address
		ADMIN_EMAIL=${ADMIN_EMAIL:-$ADMIN_USER\@$FQDN}
		export NOUSE_FTP=${OPT_NO_FTP}
	fi
	
	## db configuration
	DBHOST=${DBHOST:-localhost}
	if [ "$DBHOST" = 'localhost' ] ; then
		DBROOTPASS=${DBROOTPASS:-$(k_mkpasswd)}
		USE_INTERNALDB=1
		if [ "$KUSANAGI_DB_SYSTEM" = "mariadb" ]; then
			$DBHOST="localhost:/var/run/mysqld/mysqld.sock";
		fi
	fi
	DBNAME=${DBNAME:-$(k_mkusername)}
	DBUSER=${DBUSER:-$(k_mkusername)}
	DBPASS=${DBPASS:-$(k_mkpasswd)}
	if [ $DBHOST = "localhost" ] ; then
		[ $APP = "wp" ] && DBHOST=localhost:/var/run/mysqld/mysqld.sock
	else
		export NOUSE_DB=1
	fi

	MACHINE=$(k_machine)
	
	mkdir $PROFILE
	cat <<EOF > $PROFILE/.kusanagi
PROFILE=$NEW_PROFILE
MACHINE=$MACHINE
TARGET=$PROFILE:$(pwd)/$PROFILE
DOCUMENTROOT=/home/kusanagi/$PROFILE
KUSANAGI_PROVISION=$APP
KUSANAGI_DB_SYSTEM=$KUSANAGI_DB_SYSTEM
EOF
	cat <<EOF > $PROFILE/.kusanagi.httpd
FQDN=$FQDN
DONOT_USE_FCACHE=1
DONOT_USE_NAXSI=1
NO_USE_SSLST=1
NO_SSL_REDIRECT=1
EOF
	[ "x$APP" = "xwp" ] && cat <<EOF > $PROFILE/.kusanagi.wp
KUSANAGIPASS=$KUSANAGI_PASS
WP_TITLE=$WP_TITLE
DONOT_USE_BCACHE=1
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS
ADMIN_EMAIL=$ADMIN_PASS
EOF
	cat <<EOF > $PROFILE/.kusanagi.db
DBHOST=$HOST
DBNAME=$DBNAME
BUSER=$DBUSER
DBPASS=$DBPASS
EOF
	if [ $USE_INTERNALDB -eq 1 ] ; then
		if [ "$KUSANAGI_DB_SYSTEM" = "mariadb" ] ; then
			cat <<EOF > $PROFILE/.kusanagi.mysql
MYSQL_ROOT_PASSWORD=$DBROOTPASS
MYSQL_DATABASE=$DBNAME
MYSQL_USER=$DBUSER
MYSQL_PASSWORD=$DBPASS
EOF
		elif [ "KUSANAGI_DB_SYSTEM" = "pgsql" ] ; then
			cat <<EOF > $PROFILE/.kusanagi.pgsql
POSTGRES_DB=$DBNAME
POSTGRES_USER=$DBUSER
POSTGRES_PASSWORD=$DBPASS
POSTGRES_INITDB_ARGS=--encoding=UTF-8
EOF
		fi
	fi

	k_target $PROFILE
	cd $PROFILE
	[ "$MACHINE" != "localhost" ] && eval $(docker-machine $MACHINE env)
	[ -f "$LIBDIR/$APP.sh" ] || (k_print_error "$APP $(eval_gettext "is not implemented.")" && return 1)
	source "$LIBDIR/$APP.sh" || return 1

	local ENTRY=1
	while [ "x$ENTRY" != "x" ] ; do
		ENTRY=$(docker-compose exec nginx ps | grep 'docker-entrypoint.sh') 
	done

	mkdir contents
	docker-compose exec httpd tar cf - -C $DOCUMENTROOT . | tar xf - contents

	# save SSL_DHPARAM
	SSL_DHPARAM=$(docker-compose exec httpd cat /etc/*/dhparam.key)
	echo "SSL_DHPARAM=$SSL_DHPARAM" >> $PROFILE/.kusanagi.httpd

	# use let's encrypt
	if [ "x$MAILADDR" != "x" ] ; then
		docker-compose run certbot certonly --text \
		       	--noninteractive --webroot -w /usr/share/httpd/html/ -d $FQDN -m $MAILADDR --agree-tos
		local FULLCHAINPATH=$(ls -1t /etc/letsencrypt/live/$FQDN*/fullchain.pem 2> /dev/null |head -1)
		local LETSENCRYPTDIR=${FULLCHAINPATH%/*}  # dirname
		if [ -n "$FULLCHAINPATH" ] ; then
			docker-compose run --rm -e RENEWD_LINAGE=${LETSENCRYPTDIR} httpd /usr/bin/ct-submit.sh
		else
			# certbot-auto was failed.
			k_print_error $(eval_gettext "Cannot get Let\'s Encrypt SSL Certificate files.") #'
			return 1
		fi
		echo "SSL_CERT=${LETSENCRYPTDIR}/fullchain.pem" >> $PROFILE/.kusanagi.httpd
		echo "SSL_KEY=${LETSENCRYPTDIR}/privkey.pem" >> $PROFILE/.kusanagi.httpd
		docker-compose down httpd
		docker-compose up -d httpd
	fi
}

