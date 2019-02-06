##
# KUSANAGI provision for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

function k_provision () {
	local OPT_WOO=	# use WooCommerce option(1 = use/other no use)
	local OPT_WPLANG OPT_FQDN OPT_EMAIL OPT_DBHOST OPT_DBROOTPASS
	local OPT_DBNAME OPT_DBUSER OPT_DBPASS OPT_KUSANAGI_PASS OPT_DBSYSTEM
	local WPLANG=en_US FQDN= MAILADDR= DBHOST= DBROOTPASS= DBNAME= DBUSER= DBPASS=
	local ADMIN_USER= ADMIN_PASS= KUSANAGI_PASS= WP_TITLE= GITPATH= TARPATH=
	local OPT_NGINX= OPT_HTTPD=
	local OPT PRE_OPT
	local APP=
	local OPT_NO_EMAIL=1
	local OPT_NO_FTP=
	local USE_INTERNALDB=0
	local KUSANAGI_DB_SYSTEM=
	## perse arguments
	shift
	for OPT in "$@"
	do
		# skip 1st argment "provision"
		if [ $OPT_WPLANG ] ; then
			if [ "$OPT" =  "en_US" ] -o [ "$OPT" = "ja" ] ; then
				WPLANG="$OPT"
				OPT_WPLANG=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input 'en_US' or 'ja'.")
				return 1
			fi
		elif [ $OPT_FQDN ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,}$ ]]; then
				FQDN="$OPT"
				OPT_FQDN=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input [a-zA-Z0-9._-] 3 characters minimum.")
				return 1
			fi
		elif [ $OPT_EMAIL ] ; then
			if [[ "${OPT,,}" =~ ^[a-z0-9!$\&*.=^\`|~#%\'+\/?_{}-]+@([a-z0-9_-]+\.)+(xx--[a-z0-9]+|[a-z]{2,})$ ]] ; then #'`
				MAILADDR="$OPT"
				OPT_EMAIL=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input Valid email address.")
				return 1
			fi
		elif [ $OPT_DBHOST ] ; then
			if [[ "$OPT" =~ ^(([a-zA-Z][a-zA-Z0-9-]{0,22}[a-zA-Z0-9]\.?)+|(([0-9A-Fa-f]{0,4}::?)+[0-9A-Fa-f]{0,4})$ ]] ; then
				DBHOST="$OPT"
				OPT_DBHOST=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input valid hostname.")
				return 1
			fi
		elif [ $OPT_DBNAME ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,64}$ ]]; then
				DBNAME="$OPT"
				OPT_DBNAME=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input [a-zA-Z0-9._-] 3 to 64 characters.")
				return 1
			fi
		elif [ $OPT_DBUSER ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,16}$ ]] ; then
				DBUSER="$OPT"
				OPT_DBUSER=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter username for database. USE [a-zA-Z0-9.!#%+_-] 3 to 16 characters.")
				return 1
			fi
		elif [ $OPT_DBPASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				DBPASS="$OPT"
				OPT_DBPASS=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter password for database user 'DBUSER'. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
		elif [ $OPT_DBROOTPASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				DBROOTPASS="$OPT"
				OPT_DBROOTPASS=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter password for database user 'root'. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
			elif [ $OPT_ADMIN_USER ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{4,}$ ]] ; then
				ADMIN_USER="$OPT"
				OPT_ADMIN_USER=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter admin username for WordPress. USE [a-zA-Z0-9._-] 4 characters minimum.")
				return 1
			fi
		elif [ $OPT_DBSYSTEM ] ; then
			case in "$OPT";
			'mysql'|'mariadb')
				if [ "x$KUSANAGI_DB_SYSTEM" = "x" -o "$KUSANAGI_DB_SYSTEM" = "mariadb" ] ; then
					KUSANAGI_DB_SYSTEM=mariadb
				else
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not be specified with:") --postgresql|--pgsql.
				fi
				;;
			'postgresql'|'pgsql')
				if [ "x$KUSANAGI_DB_SYSTEM" = "x" -o "$KUSANAGI_DB_SYSTEM" = "mariadb" ] ; then
					KUSANAGI_DB_SYSTEM=pgsql
				else
					k_print_error $(eval_gettext "option:") $OPT: $(eval_gettext "can not be specified with:") --mysql|--mariadb.
				fi
				;;
			'*')
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "can not be specified.")
			esac
			OPT_DBSYSTEM=
		elif [ $OPT_ADMIN_PASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				ADMIN_PASS="$OPT"
				OPT_ADMIN_PASS=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter admin password for WordPress. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
		elif [ $OPT_KUSANAGI_PASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				KUSANAGI_PASS="$OPT"
				OPT_KUSANAGI_PASS=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter kusanagi user password for WordPress. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
		elif [ $OPT_WP_TITLE ] ; then
			if [[ "$OPT" =~ ^.{1,}$ ]] ; then
				WP_TITLE="$OPT"
				OPT_WP_TITLE=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter Title for for WordPress. USE 1 characters minimum.")
				return 1
			fi
		elif [ $OPT_GIT ] ; then
			if [ -f "$OPT" ] ; then
				GITPATH="$OPT"
				OPT_GIT=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "file not found.")
				return 1
			fi
		elif [ $OPT_TAR ] ; then
			if [ -f "$OPT" ] ; then
				TARPATH="$OPT"
				OPT_TAR=
			else
				k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "file not found.")
				return 1
			fi
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
			'--fqdn')
				OPT_FQDN=1
				;;
			'--email'|'--ssl')
				OPT_EMAIL=1
				OPT_NO_EMAIL=0
				;;
			'--dbhost')
				OPT_DBHOST=1
				;;
			'--dbrootpass')
				OPT_DBROOTPASS=1
				;;
			'--dbname')
				OPT_DBNAME=1
				;;
			'--dbuser')
				OPT_DBUSER=1
				;;
			'--dbpass')
				OPT_DBPASS=1
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
			'--kusanagi-pass')
				OPT_KUSANAGI_PASS=1
				;;
			'--admin_pass')
				OPT_ADMIN_PASS=1
				;;
			'--wp-title')
				OPT_WP_TITLE=1
				;;
			'--git')
				OPT_GIT=1
				;;
			'--tar'|'--tarball')
				OPT_TAR=1
				;;
			'--dbsystem')
				OPT_DBSYSTEM=1
				;;
			-*)				# skip other option
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
	
	## option check
	if [ $OPT_NGINX -a $OPT_HTTPD ] ; then
		k_print_error $(eval_gettext "--nginx and --httpd is can not specify both at the same time.")
		return 1
	fi

	## check profile name and directory 
	if [[ ! $NEW_PROFILE =~ ^[a-zA-Z0-9._-]{3,24}$ ]]; then
		k_print_error $(eval_gettext "Target name requires [a-zA-Z0-9._-] 3-24 characters.")
		return 1
	fi
	
	# for config
	KUSANAGI_TYPE=$APP
	KUSANAGI_DIR=$TARGET_DIR
	
	## fqdn
	if [ -z "$FQDN" ]; then
		k_print_error $(eval_gettext "require option --fqdn for your website. ex) kusanagi.tokyo.")
		return false
	fi

	if [ "wp" = $APP ]; then
		WPLANG=${WPLANG:-ja}
		## kusanagi user password
		KUSANAGI_PASS=${KUSANAGI_PASS:-$(k_mkpassword)}
		# admin user
		ADMIN_USER=${ADMIN_USER:-$(k_mkusername)}
		# admin password
		ADMIN_PASS=${ADMIN_PASS:-$(k_mkpassword)}
		# admin email address
		ADMIN_EMAIL=${ADMIN_EMAIL:-$ADMIN_USER\@$FQDN}
		export NOUSE_FTP=${OPT_NO_FTP}
	fi
	
	## db configuration
	DBHOST=${DBHOST:-localhost}
	if [ "x$DBHOST" = 'xlocalhost' ] ; then
		$DBROOTPASS=${DBROOTPASS:-$(k_mkpassword)}
		USE_INTERNALDB=1
		if [ "$KUSANAGI_DB_SYSTEM" = "mysql" ]; then
			$DBHOST="localhost:/var/run/mysqld/mysqld.sock";
		fi
	fi
	DBNAME=${DBNAME:-$(k_mkusername)}
	DBUSER=${DBUSER:-$(k_mkusername)}
	DBPASS=${DBPASS:-$(k_mkpassword)}
	if [ $DBHOST = "localhost" ] ; then
		[ $APP = "wp" ] && DBHOST=localhost:/var/run/mysqld/mysqld.sock
	else
		export NOUSE_DB=1
	fi

#	KUSANAGI_PSQL=no
	MACHINE=$(k_mahcine)
	
	mkdir $PROFILE
	cat <<EOF > $PROFILE/.kusanagi
PROFILE=$NEW_PROFILE
MACHINE=$MACHINE
TARGET=$PROFILE:$(pwd)/$PROFILE
DOCUMENTROOT=/home/kusanagi/$PROFILE
KUSANAGI_PROVISION=$APP
EOF
	cat <<EOF > $PROFILE/.kusanagi.httpd
FQDN=$FQDN
DONOT_USE_FCACHE=1
DONOT_USE_NAXSI=1
NO_USE_SSLST=1
NO_SSL_REDIRECT=1
EOF
	cat <<EOF > $PROFILE/.kusanagi.wp
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
		if [ "$KUSANAGI_DB_SYSTEM" = "mysql" ] ; then
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
	source $LIBDIR/$APP.sh || return 1

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

