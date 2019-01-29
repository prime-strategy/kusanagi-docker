##
# KUSANAGI provision for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

function k_provision () {
	local OPT_WOO=	# use WooCommerce option(1 = use/other no use)
	local OPT_WPLANG OPT_FQDN OPT_EMAIL OPT_DBHOST OPT_DBROOTPASS OPT_DBNAME OPT_DBUSER OPT_DBPASS OPT_KUSANAGI_PASS
	local WPLANG=en_US FQDN= MAILADDR= DBHOST= DBROOTPASS= DBNAME= DBUSER= DBPASS=
	local ADMIN_USER= ADMIN_PASS= KUSANAGI_PASS= WP_TITLE= GITPATH= TARPATH=
	local OPT PRE_OPT
	local APP='wp'
	local OPT_NO_EMAIL=1
	local OPT_NO_FTP=
	## perse arguments
	shift
	for OPT in "$@"
	do
		# skip 1st argment "provision"
		if [ $OPT_WPLANG ] ; then
			if [ "$OPT" =  "en_US" -o "$OPT" = "ja" ] ; then
				WPLANG="$OPT"
				OPT_WPLANG=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input 'en_US' or 'ja'.")
				return 1
			fi
		elif [ $OPT_FQDN ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,}$ ]]; then
				FQDN="$OPT"
				OPT_FQDN=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input [a-zA-Z0-9._-] 3 characters minimum.")
				return 1
			fi
		elif [ $OPT_EMAIL ] ; then
			if [[ "${OPT,,}" =~ ^[a-z0-9!$\&*.=^\`|~#%\'+\/?_{}-]+@([a-z0-9_-]+\.)+(xx--[a-z0-9]+|[a-z]{2,})$ ]] ; then #'`
				MAILADDR="$OPT"
				OPT_EMAIL=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input Valid email address.")
				return 1
			fi
		elif [ $OPT_DBHOST ] ; then
			if [[ "$OPT" =~ ^([a-zA-Z][a-zA-Z0-9-]{0,22}[a-zA-Z0-9]\.?)+$ -o "$OPT" =~ ^([0-9A-Fa-f]{0,4}::?)+[0-9A-Fa-f]{0,4}$ ]] ; then
				DBHOST="$OPT"
				OPT_DBHOST=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input valid hostname.")
				return 1
			fi
		elif [ $OPT_DBNAME ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,64}$ ]]; then
				DBNAME="$OPT"
				OPT_DBNAME=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input [a-zA-Z0-9._-] 3 to 64 characters.")
				return 1
			fi
		elif [ $OPT_DBUSER ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,16}$ ]] ; then
				DBUSER="$OPT"
				OPT_DBUSER=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter username for database. USE [a-zA-Z0-9.!#%+_-] 3 to 16 characters.")
				return 1
			fi
		elif [ $OPT_DBPASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				DBPASS="$OPT"
				OPT_DBPASS=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter password for database user 'DBUSER'. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
		elif [ $OPT_DBROOTPASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				DBROOTPASS="$OPT"
				OPT_DBROOTPASS=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter password for database user 'root'. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
			elif [ $OPT_ADMIN_USER ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{4,}$ ]] ; then
				ADMIN_USER="$OPT"
				OPT_ADMIN_USER=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter admin username for WordPress. USE [a-zA-Z0-9._-] 4 characters minimum.")
				return 1
			fi
		elif [ $OPT_ADMIN_PASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				ADMIN_PASS="$OPT"
				OPT_ADMIN_PASS=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter admin password for WordPress. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
		elif [ $OPT_KUSANAGI_PASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				KUSANAGI_PASS="$OPT"
				OPT_KUSANAGI_PASS=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter kusanagi user password for WordPress. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
		elif [ $OPT_WP_TITLE ] ; then
			if [[ "$OPT" =~ ^.{1,}$ ]] ; then
				WP_TITLE="$OPT"
				OPT_WP_TITLE=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "Enter Title for for WordPress. USE 1 characters minimum.")
				return 1
			fi
		elif [ $OPT_GIT ] ; then
			if [ -f "$OPT" ] ; then
				GITPATH="$OPT"
				OPT_GIT=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "file not found.")
				return 1
			fi
		elif [ $OPT_TAR ] ; then
			if [ -f "$OPT" ] ; then
				TARPATH="$OPT"
				OPT_TAR=
			else
				echo $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "file not found.")
				return 1
			fi
		else
			case "${OPT}" in
			'--woo'|'--WooCommerce')
				OPT_WOO=1
				;;
			'--wordpress'|'--WordPress')
				APP='wp'
				;;
			'--c5'|'--concrete5')
				APP='c5'
				;;
			'--lamp'|'--LAMP')
				APP='lamp'
				;;
			'--drupal'|'--drupal8')
				APP='drupal8'
				;;
			'--rails'|'--RubyonRails')
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
			-*)				# skip other option
				echo $(eval_gettext "Cannot use option \$OPT")
				return 1
				;;
			*)
				NEW_PROFILE="$OPT"
				break			# enable 1st (no option) string
			esac
		fi
		PRE_OPT=$OPT
	done
	
	## check profile name and directory 
	if [[ ! $NEW_PROFILE =~ ^[a-zA-Z0-9._-]{3,24}$ ]]; then
		echo $(eval_gettext "Failed. Profile name requires [a-zA-Z0-9._-] 3-24 characters.")
		return 1
	fi
	
	# for config
	KUSANAGI_TYPE=$APP
	KUSANAGI_DIR=$TARGET_DIR
	
	## fqdn
	if [ -z "$FQDN" ]; then
		echo $(eval_gettext "require option --fqdn for your website. ex) kusanagi.tokyo")
		return false
	fi

	if [ "wp" = $APP ]; then
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
	if [ $DBHOST = 'localhost' ] ; then
		$DBROOTPASS=${DBROOTPASS:-$(k_mkpassword)}
		KUSANAGI_MARIADB=yes
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
	cat <<"EOF" > $PROFILE/.kusanagi
PROFILE=$NEW_PROFILE
MACHINE=$MACHINE
TARGET=$PROFILE:$(pwd)/$PROFILE
DOCUMENTROOT=/home/kusanagi/$PROFILE
KUSANAGI_PROVISION=$APP
KUSANAGIPASS=$KUSANAGI_PASS
WP_TITLE=$WP_TITLE
FQDN=$FQDN
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS
ADMIN_EMAIL=$ADMIN_PASS
DBHOST=$HOST
DBNAME=$DBNAME
BUSER=$DBUSER
DBPASS=$DBPASS
MYSQL_ROOT_PASSWORD=$DBROOTPASS
MYSQL_DATABASE=$DBNAME
MYSQL_USER=$DBUSER
MYSQL_PASSWORD=$DBPASS
NO_USE_NAXSI=1
NO_SSL_REDIRECT=1
DONOT_USE_FCACHE=1
DONOT_USE_BCACHE=1
SSL_EMAIL=$MAILADDR
EOF

	k_target $PROFILE
	cd $PROFILE
	[ "$MACHINE" != "localhost" ] && eval $(docker-machine $MACHINE env)
	source $LIBDIR/$APP.sh
}

