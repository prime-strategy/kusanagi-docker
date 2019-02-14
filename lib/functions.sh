#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#
GLOBAL_KUSANAGI_FILE=$HOME/.kusanagi/.kusanagi
LOCAL_KUSANAGI_FILE=.kusanagi
CONFIGCMD="docker-compose run --rm config"
export TEXTDOMAIN="kusanagi-docker" 
export TEXTDOMAINDIR="$LIBDIR/locale"
source /usr/bin/gettext.sh

# make random username
function k_mkusername() {
	openssl rand -base64 1024 | fold -w 10 | egrep -e '^[a-zA-Z][a-zA-Z0-9]+$'| head -1
}

# make random password
function k_mkpasswd() {
	openssl rand -base64 1024 | fold -w 23 | egrep -e '^[!-/a-zA-Z0-9]+$'| head -1
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
init [docker-machine|localhost]
  - print docker machine
  - set docker machine
provision [options] --fqdn domainname target
	--fqdn domainname(like kusanagi.tokyo)
        [--WordPress [--wplang en_US|ja]
	  [--admin-user admin] [--admin-passwd pass] [--admin-email email]
	  [--wp-title title] [--kusanagi-pass pass] [--notfp|--no-ftp] |
	 --lamp|--concrete5|--drupal]
        [--email|-ssl email@example.com]
        [--dbhost host] [--dbname dbname]
	[--dbuser username] [--dbpass password]
	[--git giturl|--tar tarball]
ssl [options] target
        [--email|--ssl email@example.com]
	[--cert file --key file]
        [--redirect|--noredirect]
        [--hsts  {on|off}]
        [--oscp  [on|off]]
        [--ct  [on|off] [--no-register|--noregister]]
        [--renew]
config command target
	bcache [on|off]
	fcache [on|off]
	pull
	push
	tag tag
	log
	commit [--tag tag]
	checkout [--tag tag]
	dbdump
	dbrestore
	backup
	restore
remove [-y] [target]
---------------------
- status -
[-V|--version]
start|stop|restart|status [httpd|php7|db] [target]
----------------------
EOD
}

function k_target() {
	local _target="$1"
	# set target
	if [ "x$_target" != "x" ] ; then
		# target directory is found
		if [ -d "$_target" ] ; then
			TARGET="$_target:$(pwd)/$_target"
		# target directory is not found
		else
			k_print_error "$_target $(eval_gettext 'not found.')"
		fi
	# when LOCAL_KUSANAGIFILE is found, use this files TARGET entry
	elif [ -f $LOCAL_KUSANAGI_FILE ] ; then
		eval $(grep ^TARGET= "$LOCAL_KUSANAGI_FILE" 2> /dev/null)
	# when GLOBAL_KUSANAGI_FILE is not found, error exit.
	else 
		TARGET=$(grep ^TARGET= "$GLOBAL_KUSANAGI_FILE" 2> /dev/null)
	fi

	# when TARGET is not defind, error exit.
	if [ "x$TARGET" = "x" ] ; then
		k_print_error "$(eval_gettext 'TARGET has not been set.')"
		false
	else
		export TARGETDIR=${TARGET##:*} TARGET=${TARGET%%:*}
		export CONTENTDIR=$TARGETDIR/contents 
		export BASEDIR=$(dirname $DOCUMENTROOT)
		if [ "$_target" != "$TARGET" ] ; then
		#	k_rewrite TARGET "$TARGET:$TARGETDIR" $LOCAL_KUSANAGI_FILE && \
			k_rewrite TARGET "$TARGET:$TARGETDIR" $GLOBAL_KUSANAGI_FILE 
		fi
	fi
}

function k_init {
	local _init=$2
	k_target
	export MACHINE=$(k_machine "$_init")
}

function k_machine() {
	local _machine=$1
	if [ "x$_machine" = "x" ] ; then
		if [ -f "$TARGETDIR/$LOCAL_KUSANAGI_FILE" ] ; then
			eval $(grep ^MACHINE= "$TARGETDIR/$LOCAL_KUSANAGI_FILE")
		elif [ -f "$GLOBAL_KUSANAGI_FILE" ] ; then
			eval $(grep ^MACHINE= "$GLOBAL_KUSANAGI_FILE")
		else
			MACHINE=localhost
		fi
	elif [ "$_machine" != "localhost" ] ; then
		docker-machine ls | grep $_machine 2>&1 > /dev/null
		if [ $? -eq 1 ] ; then
			k_print_error "$_machine $(eval_gettext 'is not found.')"
			return false
		fi
	fi

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
	echo $MACHINE
}

function k_wpconfig() {
	local WPCONFIG=$($CONFIGCMD ls $BASEDIR/wp-config.php 2> /dev/null)
	[ "x$WPCONFIG" = "x" ] && WPCONFIG=$($CONFIGCMD ls $DOCUMENTROOT/wp-config.php 2> /dev/null)
	if [ $WPCONFIG ] ; then
		k_print_error "wp-config.php $(eval_gettext 'is not found.')"
		return false
	fi
	echo $WPCONFIG
}

function k_strartstop() {
	local _cmd=$1
	local _arg2=$2
	local _arg3=$3
	local _service _target
	case "$_arg2" in
		httpd|php7|mysql)
			_service=$_arg2
			;;
		"")
			;;
		*)
		if [ -z $_arg3 ] ; then
			_target=$_arg2
		else
			k_print_error $_cmd: $_arg2 $(eval_gettext "service not found.")
			return 1
		fi
	esac
	k_target $_target
	k_machine > /dev/null

	cd $TARGETDIR && docker-compose $_cmd $_service
}

function k_remove() {
	k_target $2
	k_machine > /dev/null

	local _PWD=$(pwd)
	cd $TARGETDIR \
	&& docker-compose stop -d \
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
	if [ "$OPT" = "on" -o "$OPT" = "off"] ; then
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
		sed -i "s/^$_var=.*$/$_var=$_val/" $_file
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
	k_is_tty && echo -e "\e[31m${OUT}\e[m" || echo "$OUT"
}

function k_print_green () {
	local OUT="${1}"
	k_is_tty && echo -e "\e[32m${OUT}\e[m" || echo "$OUT"
}

function k_print_yellow () {
	local OUT="${1}"
	k_is_tty && echo -e "\e[33m${OUT}\e[m" || echo "$OUT"
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

