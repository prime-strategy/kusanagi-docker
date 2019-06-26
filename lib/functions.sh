#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#
LOCAL_KUSANAGI_FILE=.kusanagi
CONFIGCMD="docker-compose run --rm config"
export TEXTDOMAIN="kusanagi-docker" 
export TEXTDOMAINDIR="$LIBDIR/locale"
source /usr/bin/gettext.sh
  
function k_configcmd() {
	local _dir=$1
	shift
	docker-compose run --rm -w $_dir config $@
}

function k_configcmd_root() {
	local _dir=$1
	shift
	docker-compose run --rm -u 0 -w $_dir config $@
}



# make random username
function k_mkusername() {
	openssl rand -base64 1024 | fold -w 10 | egrep -e '^[a-zA-Z][a-zA-Z0-9]+$'| head -1
}

# make random password
function k_mkpasswd() {
	openssl rand -base64 1024 | fold -w 23 | egrep -e '^[!-/a-zA-Z0-9]+$'| head -1 | sed 's|/|%|g'
}

function k_version() {
	[ -f $KUSANAGIDIR/.version] && cat $KUSANAGIDIR/.version || (k_print_error "version not defined."; false)
}

function k_help() {
	cat << EOD
///////////////////////////////////////////////////
High-Performance WordPress VirtualMachine
///////////////////////////////////////////////////
     __ ____  _______ ___    _   _____   __________
    / //_/ / / / ___//   |  / | / /   | / ____/  _/
   / ,< / / / /\__ \/ /| | /  |/ / /| |/ / __ / /
  / /| / /_/ /___/ / ___ |/ /|  / ___ / /_/ // /
 /_/ |_\____//____/_/  |_/_/ |_/_/  |_\____/___/

KUSANAGI-DOCKER CLI Subcommand inforamtion
Manual : http://en.kusanagi.tokyo/document/command/
---------------------
- help -
# kusanagi-docker [-h | --help | help]
show this snippet.
# kusanagi-docker [-V|--version]
show this version
---------------------
- create/remove target -
EOD
	k_helphelp provision help
	k_helphelp remove help
	echo '- configuration (runs on target dir) -'
	k_helphelp ssl help
	k_helphelp config help
	cat <<EOD
wp [wpcli commands]
import/export
---------------------
- status (runs on target dir) -
start|stop|restart|status
----------------------
EOD
}

function k_helphelp {
	case $2 in
	'help'|'--help')
		case $1 in
			provision)
				echo $(eval_gettext "provision [options] --fqdn domainname target(like kusanagi.tokyo)")
				echo "	"$(eval_gettext "[--WordPress [--wplang lang(like en_US, ja)]")
				echo "		"$(eval_gettext "[--admin-user admin] [--admin-passwd pass] [--admin-email email]")
				echo "		"$(eval_gettext "[--wp-title title] [--kusanagi-pass pass] [--notfp|--no-ftp] |")
				echo "	"$(eval_gettext ' --lamp|--concrete5|--drupal|--drupal7|--drupal8]')
				echo "	"$(eval_gettext "[--dbhost host]")
				echo "	"$(eval_gettext "[--dbname dbname]")
				echo "	"$(eval_gettext "[--dbuser username]")
				echo "	"$(eval_gettext "[--dbpass password]")

#				echo "	"$(eval_gettext "Option: --wordpress|--WordPress")
#				echo "		"$(eval_gettext "Provision new profile to use WordPress.")
#				echo "	"$(eval_gettext "Option: --woo|--WooCommerce")
#				echo "		"$(eval_gettext "Provision WordPress with WooCommerce plugin.")
#				echo "	"$(eval_gettext "Option: --lamp")
#				echo "		"$(eval_gettext "Provision new profile to use LAMP.")
#				echo "	"$(eval_gettext "Option: --c5|--concrete5")
#				echo "		"$(eval_gettext "Provision new profile to use Concrete5.")
#				echo "	"$(eval_gettext "Option: --drupal7")
#				echo "		"$(eval_gettext "Provision new profile to use Drupal7.")
#				echo "	"$(eval_gettext "Option: --drupal|--drupal8")
#				echo "		"$(eval_gettext "Provision new profile to use Drupal8.")
#				echo "	"$(eval_gettext "Option: --wplang [en_US|ja]")
#				echo "		"$(eval_gettext "Set WordPress Language english(en_US) or Japanese(ja).")
#				echo "		"$(eval_gettext "If do not specify it, use choose this parameter interactively.")
#				echo "	"$(eval_gettext "Option: --fqdn domainname")
#				echo "		"$(eval_gettext "Set host name to new domainname.")
#				echo "	"$(eval_gettext "Option: --email mail_address")
#				echo "		"$(eval_gettext "Set Email address to Let's Encrypt certiticates.")
#				echo "		"$(eval_gettext "If do not specify --email and --no-email, use choose this parameter interactively.")
#				echo "	"$(eval_gettext "Option: --no-email|--noemail")
#				echo "		"$(eval_gettext "Unset Email address, and Do not execute Let's Encrypt certiticates.")
#				echo "		"$(eval_gettext "If do not specify --email and --no-email, use choose this parameter interactively.")
#				echo "	"$(eval_gettext "Option: --dbname name")
#				echo "		"$(eval_gettext "Set MySQL Database name.")
#				echo "		"$(eval_gettext "If do not specify it, use choose this parameter interactively.")
#				echo "	"$(eval_gettext "Option: --dbuser user")
#				echo "		"$(eval_gettext "Set MySQL Database user name.")
#				echo "		"$(eval_gettext "If do not specify it, use choose this parameter interactively.")
#				echo "	"$(eval_gettext "Option: --dbpass password")
#				echo "		"$(eval_gettext "Set MySQL Database user's password.")
#				echo "		"$(eval_gettext "If do not specify it, use choose this parameter interactively.")
				;;
			config)
				echo $(eval_gettext "config command ")
				echo "	"$(eval_gettext "bcache [on|off]")
				echo "	"$(eval_gettext "fcache [on|off]")
				echo "	"$(eval_gettext "pull")
				echo "	"$(eval_gettext "push")
				echo "	"$(eval_gettext "dbdump [file]")
				echo "	"$(eval_gettext "dbrestore [file]")
				echo "	"$(eval_gettext "backup")
				echo "	"$(eval_gettext "restore")
				echo "	"$(eval_gettext "[--help|help]")
#				echo $(eval_gettext "Setting: Change site URL to target profile.")
#				echo "	"$(eval_gettext "Argument: --fqdn domainname [profile]")
#				echo "	"$(eval_gettext "Option: --fqdn domainname")
#				echo "		"$(eval_gettext "Change existing host name to domainname.")
#				echo "	"$(eval_gettext "Option: [profile]")
#				echo "		"$(eval_gettext "Target Profile name. If do not specify it, use the current profile.")
				;;
			ssl)
				echo $(eval_gettext "ssl [options]")
				echo "	"$(eval_gettext "[--cert file --key file]")
				echo "	"$(eval_gettext "[--redirect|--noredirect]")
				echo "	"$(eval_gettext "[--hsts  [on|off]]")
				echo "	"$(eval_gettext "[--oscp  [on|off]]")
				echo "	"$(eval_gettext "[--ct  [on|off] [--no-register|--noregister]]")
				echo "	"$(eval_gettext "[--help|help]")

#				echo $(eval_gettext "SSL: modify SSL Certificate configurations.")
#				echo "	"$(eval_gettext "Option: --email email@example.com")
#				echo "		"$(eval_gettext "Create new Let's Encrypt certificate to target profile.")
#				echo "		"$(eval_gettext "Specified your E-Mail address(to use expire notice email,etc...)")
#				echo "	"$(eval_gettext "Option: --cert certfile --key keyfile")
#				echo "		"$(eval_gettext "Use specified certificate and key files.")
#				echo "		"$(eval_gettext "These option cannot use with --email option.")
#				echo "	"$(eval_gettext "Option: --https [redirect|noredirect]")
#				echo "		"$(eval_gettext "Redirect or No Redirect HTTP to HTTPS site to target profile.")
#				echo "	"$(eval_gettext "Option: --hsts [off|weak|mid|high]")
#				echo "		"$(eval_gettext "use HSTS(HTTP Strict Transport Security) setting.")
#				echo "		"$(eval_gettext "off:  Disable HSTS")
#				echo "		"$(eval_gettext "weak: Enabling HSTS(not IncludeSubDomain)")
#				echo "		"$(eval_gettext "mid:  Enabling HSTS w/IncludeSubDomain (not Preloading)")
#				echo "		"$(eval_gettext "high: Enabling HSTS w/IncludeSubDomain,Preloading")
#				echo "	"$(eval_gettext "Option: --auto [on|off]")
#				echo "		"$(eval_gettext "Enable or disable auto renewal Let's Encrypt certification.")
#				echo "	"$(eval_gettext "Option: --ct [on|off]")
#				echo "		"$(eval_gettext "Enable or disable CT(Certificate Transparency) options.")
#				echo "	"$(eval_gettext "Option: --no-register|--noregister")
#				echo "		"$(eval_gettext "Do not register SCT files to CT(Certificate Transparency) log servers.")
#				echo "		"$(eval_gettext "This Options only use with --ct Options.")
#				echo "	"$(eval_gettext "Option: [profile]")
#				echo "		"$(eval_gettext "Target Profile name. If do not specify it, use the current profile.")
				;;
#			httpd)
#				echo $(eval_gettext "HTTPd: Change using web server to Apache HTTPd.")
#				echo "	"$(eval_gettext "No need arguments.")
#				exit 0
#				;;
#			nginx)
#				echo $(eval_gettext "NGINX: Change using web server to Nginx.")
#				echo "	"$(eval_gettext "No need arguments.")
#				exit 0
#				;;
#			php-fpm)
#				echo $(eval_gettext "PHP-FPM: Change using PHP FastCGI server to PHP-FPM(version 5).")
#				echo "	" $(eval_gettext "No need arguments.")
#				exit 0
#				;;
#			php7)
#				echo $(eval_gettext "PHP7: Change using PHP FastCGI server to PHP7.")
#				echo "	"$(eval_gettext "No need arguments.")
#				exit 0
#				;;
#		status)
#				echo $(eval_gettext "Status: Show KUSANAGI middleware status and current profile.")
#				echo "	"$(eval_gettext "No need arguments.")
#				exit 0
#				;;
#			update)
#				echo $(eval_gettext "Update: Update KUSANAGI plugin or certificate.")
#				echo "	"$(eval_gettext "Argument: plugin [-y]")
#				echo "		"$(eval_gettext "Update plugins If plugin version is updated.")
#				echo "	"$(eval_gettext "Option: [-y]")
#				echo "		"$(eval_gettext "Assume yes; assume that the answer to any question which would be asked is yes.")
#				echo "	"$(eval_gettext "Argument: cert [profile]")
#				echo "		"$(eval_gettext "Update Let's Encrypt SSL Certification.")
#				echo "	"$(eval_gettext "Option: [profile]")
#				echo "		"$(eval_gettext "Target Profile name. If do not specify it, use the current profile.")
#				exit 0
#				;;
#			fcache)
#				echo $(eval_gettext "FCache: Control FCache feature.")
#				echo "	"$(eval_gettext "Argument: on")
#				echo "		"$(eval_gettext "Use FCache")
#				echo "	"$(eval_gettext "Argument: off")
##				echo "		"$(eval_gettext "Do not use FCache")
#				echo "	"$(eval_gettext "Argument: clear")
#				echo "		"$(eval_gettext "Clear FCache")
#				exit 0
#				;;
#			bcache)
#				echo $(eval_gettext "BCache: Control BCache feature.")
#				echo "	"$(eval_gettext "Argument: on")
#				echo "		"$(eval_gettext "Use BCache")
#				echo "	"$(eval_gettext "Argument: off")
#				echo "		"$(eval_gettext "Do not use BCache")
#				echo "	"$(eval_gettext "Argument: clear")
#				echo "		"$(eval_gettext "Clear BCache")
#				exit 0
#				;;
#			restart)
#				echo $(eval_gettext "Restart: restart all enabled middleweres.")
#				echo "	"$(eval_gettext "No need arguments.")
#				exit 0
#				;;
			remove)
				echo $(eval_gettext "remove [-y] [target]")
#				echo $(eval_gettext "Remove: remove setteing, contents, and DB.")
#				echo "	"$(eval_gettext "Argument: [-y] [profile]")
#				echo "	"$(eval_gettext "Option: -y")
#				echo "		"$(eval_gettext "Assume yes; assume that the answer to any question which would be asked is yes.")
#				echo "	"$(eval_gettext "Option: profile ")
#				echo "		"$(eval_gettext "Target profile. When don't you set profile, you remove current profile.")
				;;
#			-h|--help|help)
#				echo $(eval_gettext "Help: Help is this option.")
#				exit 0
#				;;
			*)
				echo $(eval_gettext "Invalid Parameters. Try 'kusanagi -h'")
				exit 1
				;;
		esac
		;;
	*)
		;;
	esac
}

function k_target() {
	local _target="$1"
	# set target
	if [ "x$_target" != "x" ] ; then
		# target directory is found
		if [ -d "$_target" ] ; then
			TARGET="$_target"
			TARGETDIR="$(pwd)/$_target"
		# target directory is not found
		else
			k_print_error "$_target $(eval_gettext 'not found.')"
		fi
	# when LOCAL_KUSANAGIFILE is found, use this files TARGET entry
	elif [ -f $LOCAL_KUSANAGI_FILE ] ; then
		source $LOCAL_KUSANAGI_FILE
	fi

	# when TARGET is not defind, error exit.
	if [ "x$TARGET" = "x" ] ; then
		k_print_error "$(eval_gettext 'TARGET has not been set.')"
		false
	else
		export CONTENTDIR=${CONTENTDIR:-"${TARGETDIR}/contents"}
		export DOCUMENTROOT=${DOCUMENTROOT:-"$BASEDIR/$ROOT_DIR"}
		export BASEDIR=$(dirname $DOCUMENTROOT)
	fi
}

function k_init {
	local _init=$2
	return
	k_target
	export MACHINE=$(k_machine "$_init" 1)
}

function k_machine() {
	local _machine=$1
	local _is_print=$2
	return
	if [ "x$_machine" = "x" ] ; then
		if [ -f "$TARGETDIR/$LOCAL_KUSANAGI_FILE" ] ; then
			eval $(grep ^MACHINE= "$TARGETDIR/$LOCAL_KUSANAGI_FILE")
		fi
		MACHINE=${MACHINE:-localhost}
	elif [ "$_machine" != "localhost" ] ; then
		docker-machine ls | grep $_machine 2>&1 > /dev/null
		if [ $? -eq 1 ] ; then
			k_print_error "$_machine $(eval_gettext 'is not found.')"
			return 1
		fi
		MACHINE=$_machine
	fi

	if [ $_is_print ] ; then
		if [ "$_machine" = "localhost" -o "$MACHINE" = "localhost" ] ; then
			[ "x$TARGETDIR" != "x" ] && \
			       	(cd $TARGETDIR && docker-compose ps 1>&2 ) || docker ps 1>&2
		else
			[ "x$TARGETDIR" != "x" ]  \
			       	&& (cd $TARGETDIR && \
			       		eval $(docker-machine env $_machine) && \
				       		docker-compose ps) 1>&2 \
				||  (eval $(docker-machine env $_machine) && docker ps 1>&2) 
		fi
	fi
	echo $MACHINE
}

function k_wpconfig() {
	local _dir
	k_configcmd $BASEDIR test -f $BASEDIR/wp-config.php && _dir=$BASEDIR
	[ "x$_dir" = "x" ] && \
		k_configcmd $DOCUMENTROOT test -f $DOCUMENTROOT/wp-config.php && _dir=$DOCUMENTROOT
	if [ "x$_dir" = "x" ] ; then
		k_print_error "wp-config.php $(eval_gettext 'is not found.')"
		return 1
	else
		echo $_dir
	fi
}

function k_startstop() {
	local _cmd=$1
	local _arg2=$2
	local _service _target
	case "$_arg2" in
		httpd|php|db|ftp)
			_service=$_arg2
			;;
		"")
			;;
		*)
			k_print_error $_cmd: $_arg2 $(eval_gettext "service not found.")
			return 1
	esac
	k\_target > /dev/null
	k_machine > /dev/null
	case $_cmd in
	'start'|'stop'|'restart'|'ps')
		cd $TARGETDIR && docker-compose $_cmd $_service
		;;
	'status')
		cd $TARGETDIR && docker-compose ps $_service
		;;
	*)
	esac

}

function k_remove() {
	k_target $2
	k_machine > /dev/null

	local _PWD=$(pwd)
	cd $TARGETDIR \
	&& docker-compose down -v \
	&& cd .. \
	&& rm -rf $TARGETDIR \
	&& ([ -d $_PWD ] && cd $_PWD || true)
}

function k_httpd() {
	k_print_error "$1 $(eval_gettext "is not implemented.")" 
}
function k_nginx() {
	k_print_error "$1 $(eval_gettext "is not implemented.")"
}
function k_update() {
	k_print_error "$1 $(eval_gettext "is not implemented.")"
}

function k_check_file() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [ -f "$OPT" ] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "file not found.")
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

function k_check_onoff() {
	local PRE_OPT="$1"
	local OPT="$2"
	if [ "$OPT" = "on" -o "$OPT" = "off" ] ; then
		echo "$OPT"
	else
		k_print_error $(eval_gettext "option:") $PRE_OPT $OPT: $(eval_gettext "please input on/off.")
	fi
}

function k_rewrite() {
	local _var=$1
	local _val=$2
	local _file=$3
	grep "^$_var=" $_file 2>&1 > /dev/null
	if [ $? -eq 0 ] ; then
		sed -i "s|^$_var=.*$|$_var=$_val|" $_file
	else
		echo "$_var=$_val" >> $_file
	fi
}

function check_status() {
	# 'Done.' Or 'Failed.' Is displayed by the return value of the previous command.
	# Please attach ${_RETURN} to the argument of exit.
	if [ "$?" -eq 0 ]; then
		k_print_info $(eval_gettext "Done.")
		exit 0
	else
		k_print_error $(eval_gettext "Failed.")
		exit 1
	fi
}

# check EXISTS_FUNC(shell variable) function has been defined
function k_is_fuction_exists () {
	local RET
	if [ "$(type -t ${EXISTS_FUNC})" = 'function' ] ; then
		RET=0
	else
		RET=1
	fi
	EXISTS_FUNC=''
	return ${RET}
}

# check the current KUSANAGI version.
function k_version () {
	cat $BASEDIR/.version
	return 0
}

# display info message
function k_print_info () {
	k_print_green "INFO: $*"
}

# display error message
function k_print_error () {
	k_print_red "ERROR: $*"
}

# display notice message
function k_print_notice () {
	k_print_yellow "NOTICE: $*"
}

function k_print_red () {
	local OUT="${1}"
	k_is_tty && echo -e "\e[31m${OUT}\e[m" || echo "$OUT" 1&>2
}

function k_print_green () {
	local OUT="${1}"
	k_is_tty && echo -e "\e[32m${OUT}\e[m" || echo "$OUT" 1&>2
}

function k_print_yellow () {
	local OUT="${1}"
	k_is_tty && echo -e "\e[33m${OUT}\e[m" || echo "$OUT" 1&>2
}
		

# check if a file descriptor is a tty.
function k_is_tty () {
	if [[ -t 1 ]]; then
		return 0
	else
		return 1
	fi
}

# check if current shell is interactive
function k_is_interactive () {
	case "$-" in
	*i*)  return 0 ;;
	*)  return 1;;
	esac
}

