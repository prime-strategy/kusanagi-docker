##
# KUSANAGI provision for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

function k_check_wplang() {
	local PRE_OPT="$1"
	local OPT="$2"
	case "$OPT" in
	af|ar|ary|as|az|azb|bel|bg_BG|bn_BD|bo|bs_BA|ca|ceb|ckb|cs_CZ|cy)
		echo "$OPT"
		;;
	da_DK|de_CH|de_CH_informal|de_DE|de_DE_formal|dzo)
		echo "$OPT"
		;;
	el|en_AU|en_CA|en_GB|en_NZ|en_US|en_ZA|eo)
		echo "$OPT"
		;;
	es_AR|es_CL|es_CO|es_CR|es_ES|es_GT|es_MX|es_PE|es_VE|et)
		echo "$OPT"
		;;
	eu|fa_IR|fi|fr_BE|fr_CA|fr_FR|fur)
		echo "$OPT"
		;;
	gd|gl_ES|gu|haz|he_IL|hi_IN|hr|hu_HU|hy)
		echo "$OPT"
		;;
	id_ID|is_IS|it_IT|ja|jv_ID|kab|ka_GE|kk|km|ko_KR|lo|lt_LT|lv)
		echo "$OPT"
		;;
	mk_MK|ml_IN|mn|mr|ms_MY|my_MM)
		echo "$OPT"
		;;
	nb_NO|ne_NP|nl_BE|nl_NL|nl_NL_formal|nn_NO)
		echo "$OPT"
		;;
	oci|pa_IN|pl_PL|ps|pt_BR|pt_PT|pt_PT_ao90)
		echo "$OPT"
		;;
	rhg|ro_RO|ru_RU|sah)
		echo "$OPT"
		;;
	si_LK|skr|sk_SK|sl_SI|sq|sr_RS|sv_SE|szl)
		echo "$OPT"
		;;
	tah|ta_IN|te|th|tl|tr_TR|tt_RU)
		echo "$OPT"
		;;
	ug_CN|uk|ur|uz_UZ|vi|zh_CN|zh_HK|zh_TW)
		echo "$OPT"
		;;
	*)
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input legal language.")
		;;
	esac
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
	if [ "x$DB" = "x" ] ; then
		k_print_notice $(eval_gettext "option:") $OPT: $(eval_gettext "can not be specified with another db system.")
	fi
	case "$OPT" in
	'mysql'|'mariadb')
		echo mysql
		;;
	'postgresql'|'pgsql')
		echo pgsql
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

function k_add_profile() {
	local OPT="$1"
	local DEFAULT="$2"
	local FILE="$3"
	if [ -v $OPT ] ; then
		echo "$OPT=${$OPT}" >> $FILE
	else
		echo "#$OPT=$DEFAULT" >> $FILE
	fi
}


function k_provision () {
	local OPT_WOO=	# use WooCommerce option(1 = use/other no use)
	local OPT_WPLANG OPT_FQDN OPT_EMAIL OPT_DBHOST OPT_DBROOTPASS
	local OPT_DBNAME OPT_DBUSER OPT_DBPASS OPT_KUSANAGI_PASS OPT_DBSYSTEM
	local OPT_NGINX OPT_HTTPD OPT_HTTP_PORT OPT_TLS_PORT
	local OPT PRE_OPT
	local WP_LANG=en_US FQDN= MAILADDR= DBHOST= DBROOTPASS= DBNAME= DBUSER= DBPASS=
	local ADMIN_USER= ADMIN_PASS= KUSANAGI_PASS= WP_TITLE= GITPATH= TARPATH=
	local OPT_NO_FTP= OPT_NO_EMAIL=1
	local HTTP_PORT=${HTTP_PORT:-80} HTTP_TLS_PORT=${HTTP_TLS_PORT:-443}
	local KUSANAGI_DB_SYSTEM= USE_INTERNALDB=0
	local APP=
	## perse arguments
	shift
	for OPT in "$@"
	do
		# skip 1st argment "provision"
		if [ $OPT_WPLANG ] ; then
			WP_LANG=$(k_check_wplang "$PRE_OPT" "$OPT")
			[ $WP_LANG != $OPT ] && return 1
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
			OPT_HTTP_PORT=
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
			'--wp'|'--wordpress'|'--WordPress')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='wp'
				KUSANAGI_DB_SYSTEM=mysql
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
			'--drupal7')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='drupal'
				DRUPAL_VERSION=7
				KUSANAGI_DB_SYSTEM=mysql
				;;
			'--drupal'|'--drupal8')
				if [ "x$APP" != "x" ] ; then
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not specified with another application.")
				fi
				APP='drupal'
				DRUPAL_VERSION=8
				KUSANAGI_DB_SYSTEM=mysql
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
			--admin-user=*)
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
			'--admin-pass')
				OPT_ADMIN_PASS=1
				;;
			--admin-pass=*)
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
				KUSANAGI_DB_SYSTEM=$(k_check_dbsystem \
					"${OPT%%=*}" "${OPT#*=}" "$KUSANAGI_DB_SYSTEM")
				[ -z $KUSANAGI_DB_SYSTEM ] && return 1
				;;
			--help|help)
				k_helphelp provision help
				return 0
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
	KUSANAGI_DB_SYSTEM=${KUSANAGI_DB_SYSTEM:-mysql}
	if [ $KUSANAGI_DB_SYSTEM = "mysql" ] ; then
		DBLIB=/var/run/mysqld
	else
		DBLIB=/var/run/pgsql
	    SMALL=1
	fi
	
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
		return 1
	fi

	if [ "wp" = $APP ]; then
		WP_TITLE=${WP_TITLE:-WordPress}
		WPLANG=${WPLANG:-ja_JP}
		## kusanagi user password
		KUSANAGI_PASS=${KUSANAGI_PASS:-$(k_mkpasswd)}
		# admin user
		ADMIN_USER=${ADMIN_USER:-$(k_mkusername)}
		# admin password
		ADMIN_PASS=${ADMIN_PASS:-$(k_mkpasswd)}
		# admin email address
		ADMIN_EMAIL=${ADMIN_EMAIL:-${ADMIN_USER}@${FQDN}}
		export NO_USE_FTP=${OPT_NO_FTP}
	fi
	
	## db configuration
	DBHOST=${DBHOST:-localhost}
	if [ "$DBHOST" = 'localhost' ] ; then
		DBROOTPASS=${DBROOTPASS:-$(k_mkpasswd)}
		#if [ "$KUSANAGI_DB_SYSTEM" = "mysql" ]; then
		#	DBHOST="localhost:/var/run/mysqld/mysqld.sock";
		#fi
	else
		export NO_USE_DB=1
	fi
	DBNAME=${DBNAME:-$(k_mkusername $SMALL)}
	DBUSER=${DBUSER:-$(k_mkusername $SMALL)}
	DBPASS=${DBPASS:-$(k_mkpasswd)}

	#MACHINE=$(k_machine)
	
	mkdir $PROFILE
	local _rootdir=$([ "c5" = $APP ] && echo public || echo DocumentRoot)
	ROOT_DIR="${ROOT_DIR:-$_rootdir}"
	DOCUMENTROOT="${DOCUMENTROOT:-/home/kusanagi/$PROFILE/$ROOT_DIR}"
	# add .kusanagi
	cat <<EOF > $PROFILE/.kusanagi
PROFILE=$PROFILE
TARGET=$PROFILE
TARGETDIR=$(pwd)/$PROFILE
DOCUMENTROOT=$DOCUMENTROOT
ROOT_DIR=$ROOT_DIR
KUSANAGI_PROVISION=$APP
KUSANAGI_DB_SYSTEM=$KUSANAGI_DB_SYSTEM
EOF

	# add .kusanagi.httpd
	cat <<EOF > $PROFILE/.kusanagi.httpd
FQDN=$FQDN
NO_USE_FCACHE=${NO_USE_FCACHE:-1}
USE_SSL_CT=${USE_SSL_CT:-off}
USE_SSL_OSCP=${USE_SSL_OSCP:-off}
NO_USE_NAXSI=${NO_USE_NAXSI:-1}
NO_USE_SSLST=${NO_USE_SSLST:-1}
NO_SSL_REDIRECT=${NO_SSL_REDIRECT:-1}
EOF
	k_add_profile EXPIRE_DAYS 90 $PROFILE/.kusanagi.httpd
	k_add_profile OSCP_RESOLV 8.8.8.8 $PROFILE/.kusanagi.httpd

	# add .kusanagi.php
	touch $PROFILE/.kusanagi.php
	k_add_profile PHP_PORT '127.0.0.1:9000' $PROFILE/.kusanagi.php
	k_add_profile PHP_MAX_CHILDLEN 500 $PROFILE/.kusanagi.php
	k_add_profile PHP_START_SERVERS 10 $PROFILE/.kusanagi.php
	k_add_profile PHP_MIN_SPARE_SERVERS 5 $PROFILE/.kusanagi.php
	k_add_profile PHP_MAX_SPARE_SERVERS 15 $PROFILE/.kusanagi.php
	k_add_profile PHP_MAX_REQUESTS 500 $PROFILE/.kusanagi.php

	# add .kusanagi.mail
	MAILSERVER=${MAILSERVER:-localhost} > $PROFILE/.kusanagi.mail
	k_add_profile MAILDOMAIN '' $PROFILE/.kusanagi.mail
	k_add_profile MAILUSER '' $PROFILE/.kusanagi.mail
	k_add_profile MAILPASS '' $PROFILE/.kusanagi.mail
	k_add_profile MAILAUTH '' $PROFILE/.kusanagi.mail

	[ "x$APP" = "xwp" ] && cat <<EOF > $PROFILE/.kusanagi.wp
KUSANAGIPASS=$KUSANAGI_PASS
WP_TITLE=$WP_TITLE
NO_USE_BCACHE=${NO_USE_BCACHE:-1}
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS
ADMIN_EMAIL=$ADMIN_EMAIL
EOF
	cat <<EOF > $PROFILE/.kusanagi.db
DBLIB=$DBLIB
DBHOST=$DBHOST
DBNAME=$DBNAME
DBUSER=$DBUSER
DBPASS=$DBPASS
EOF
	if ! [ $NO_USE_DB ] ; then
		if [ "$KUSANAGI_DB_SYSTEM" = "mysql" ] ; then
			cat <<EOF > $PROFILE/.kusanagi.mysql
MYSQL_ROOT_PASSWORD=$DBROOTPASS
MYSQL_DATABASE=$DBNAME
MYSQL_USER=$DBUSER
MYSQL_PASSWORD=$DBPASS
EOF
			k_add_profile MYSQL_ALLOW_EMPTY_PASSWORD '' $PROFILE/.kusanagi.mysql
			k_add_profile MYSQL_RANDOM_ROOT_PASSWORD '' $PROFILE/.kusanagi.mysql
			k_add_profile SOCKET '' $PROFILE/.kusanagi.mysql
			k_add_profile MYSQL_INITDB_SKIP_TZINFO '' $PROFILE/.kusanagi.mysql
			k_add_profile MYSQL_ROOT_HOST '' $PROFILE/.kusanagi.mysql
		elif [ "$KUSANAGI_DB_SYSTEM" = "pgsql" ] ; then
			cat <<EOF > $PROFILE/.kusanagi.pgsql
POSTGRES_DB=$DBNAME
POSTGRES_USER=$DBUSER
POSTGRES_PASSWORD=$DBPASS
PG_PASSWORD=$DBPASS
POSTGRES_INITDB_ARGS=--encoding=UTF-8
DATABASE_HOST=localhost
EOF
			k_add_profile PGDATA '' $PROFILE/.kusanagi.psql
			k_add_profile POSTGRES_INITDB_WALDIR '' $PROFILE/.kusanagi.psql
		fi
	fi

	k_target $PROFILE
	cd $PROFILE
	[ "$MACHINE" != "localhost" ] && eval $(docker-machine $MACHINE env)
	[ -f "$LIBDIR/$APP.sh" ] || (k_print_error "$APP $(eval_gettext "is not implemented.")" && return 1)
	source "$LIBDIR/$APP.sh" || return 1
	source "$LIBDIR/config.sh" || return 1
	mkdir -p contents/$_rootdir
	if [ "x$TARPATH" != "x" ] && [ -f $TARPATH ] ; then
		tar xf $TARFILE -C contents/$_rootdir
		k_content push
	elif [  "x$GITPATH" != "x" ] && [ -f $GITPATH ] ; then 
		git clone $GITPATH contents/$_rootdir
		k_content push
	else
		k_content pull
	fi

	local ENTRY=$(docker-compose exec httpd ps | grep 'docker-entrypoint.sh') 
	local FIRST=1
	while [ "x$ENTRY" != "x" ] ; do
		[ $FIRST ] && FIRST= && \
			echo -n -e "\e[32m" $(eval_gettext "Waiting HTTPD init process") 
		echo -n "."
		ENTRY=$(docker-compose exec httpd ps | grep 'openssl') 
		[ "x$ENTRY" = "x" ] && break
		sleep 5
	done
	echo -e "\e[m"

	# save SSL_DHPARAM
	DHPARAM=$(docker-compose exec httpd cat /etc/nginx/dhparam.key)
	[ $? -ne 0 ] && DHPARAM=$(docker-compose exec httpd cat /etc/httpd/dhparam.key)
	SSL_DHPARAM=$(echo $DHPARAM | sed -e 's/\n/ /g' -e 's/\r//g')
	echo "SSL_DHPARAM=\"$SSL_DHPARAM\"" >> .kusanagi.httpd

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
		echo "SSL_CERT=${LETSENCRYPTDIR}/fullchain.pem" >> .kusanagi.httpd
		echo "SSL_KEY=${LETSENCRYPTDIR}/privkey.pem" >> .kusanagi.httpd
		docker-compose down httpd
		docker-compose up -d httpd
	fi

	git init -q
	echo '*~' > .gitignore
	echo '.gitignore' >> .gitignore
	git add .kusanagi* contents docker-compose.yml > /dev/null
	git commit -m 'initial commit' > /dev/null
}

