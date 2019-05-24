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
---------------------
- configuration -
provision [options] --fqdn domainname target
	--fqdn domainname(like kusanagi.tokyo)
        [--WordPress [--wplang en_US|ja]
	  [--admin-user admin] [--admin-passwd pass] [--admin-email email]
	  [--wp-title title] [--kusanagi-pass pass] [--notfp|--no-ftp] |
	 --lamp|--concrete5|--drupal|--drupal7|--drupal8]
        [--email|-ssl email@example.com]
        [--dbhost host] [--dbname dbname]
	[--dbuser username] [--dbpass password]
	[--git giturl|--tar tarball]
ssl [options] 
        [--email|--ssl email@example.com]
	[--cert file --key file]
        [--redirect|--noredirect]
        [--hsts  {on|off}]
        [--oscp  [on|off]]
        [--ct  [on|off] [--no-register|--noregister]]
        [--renew]
config command 
	bcache [on|off]
	fcache [on|off]
	pull
	push
	dbdump [file]
	dbrestore [file]
	backup
	restore
remove [-y] [target]
---------------------
- status -
[-V|--version]
start|stop|restart|status
----------------------
EOD
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
		export CONTENTDIR=$TARGETDIR/contents 
		export DOCUMENTROOT=/home/kusanagi/$TARGET/DocumentRoot
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
