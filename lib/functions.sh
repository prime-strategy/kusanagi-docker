#!/bin/bash
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#

[[ $(docker compose version) ]] && DOCKER_COMPOSE="$(which docker) compose"
[[ -z "$DOCKER_COMPOSE" ]] && DOCKER_COMPOSE=$(which docker-compose)
[[ -z "$DOCKER_COMPOSE" ]] && DOCKER_COMPOSE=$(which docker-compose.exe)
LOCAL_KUSANAGI_FILE=.kusanagi
export TEXTDOMAIN="kusanagi-docker"
export TEXTDOMAINDIR="$LIBDIR/locale"
. $(which gettext.sh)

function k_compose() {
	$DOCKER_COMPOSE "$@"
}

function k_configcmd() {
	local _dir=$1
	shift
	k_compose run --rm -w "$_dir" config "$@"
}

function k_configcmd_root() {
	local _dir=$1
	shift
	k_compose run --rm -u 0 -w "$_dir" config "$@"
}

function k_db_check() {
	if [[ ${KUSANAGI_DB_SYSTEM,,} == "mariadb" ]] ; then
		k_mariadb_check
	elif [[ ${KUSANAGI_DB_SYSTEM,,} == "postgresql" ]]; then
		k_postgresql_check
	fi
	return $?
}

function k_mariadb_check() {
	local OPT=
	if [[ $NO_USE_DB ]]; then
		OPT="-h$DBHOST -P$DBPORT"
	fi
	k_compose exec db mariadb-check -c $OPT -u"$DBUSER" -p"$DBPASS" "$DBNAME" > /dev/null 2>&1
	return $?
}

function k_postgresql_check() {
	local OPT
	if [[ $NO_USE_DB ]] ; then
		OPT="--dbhost=$DBHOST --port=$DBPORT"
	fi
	k_configcmd "/" pg_isready "$OPT" --username="$DBUSER" --dbname="$DBNAME"
	return $?
}

function k_php_exec() {
	local _dir=$1
	shift
	k_compose exec -T --user 1000 -w "$_dir" php "$@"
}

function k_config_isdir() {
	local _dir=$1
	shift
	"$DOCKER_COMPOSE" run -T --rm config sh -c "test -d $_dir" 2> /dev/null
	echo $?
}

# copy file to containar
# path copy_files
function k_copy() {
	local _container_name=php
	local _container_path=$1
	local _container_id="$(k_compose ps -q $_container_name)"
	shift

	for f in "$@" ;
	do
		docker cp "$f" "${_container_id}:${_container_path}"
	done
}

# make random username
function k_mkusername() {
	local small=$1
	local user=$(openssl rand -base64 1024 | fold -w 10 | \
		egrep -e '^[a-zA-Z][a-zA-Z0-9]+$' | head -1)
	[ $small ] && echo ${user,,} || echo $user
}

# make random password
function k_mkpasswd() {
	openssl rand -base64 1024 | fold -w 23 | egrep -e '^[!-/a-zA-Z0-9]+$'| head -1 | sed 's|/|%|g'
}

function k_version() {
	[ -f $KUSANAGIDIR/.version ] && cat $KUSANAGIDIR/.version || (k_print_error "version not defined."; false)
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
				echo $(eval_gettext 'provision [options] --fqdn domainname target(like kusanagi.tokyo)')
				echo '    '$(eval_gettext '[--wp|--wordpress|--WordPress [WPOPTION]|')
				echo '    '$(eval_gettext 'WPOPTION:')
				echo '        '$(eval_gettext ' --wplang lang(like en_US, ja)]')
				echo '        '$(eval_gettext ' [--admin-user admin] [--admin-pass pass] [--admin-email email]')
				echo '        '$(eval_gettext ' [--wp-title title] [--kusanagi-pass pass] [--noftp|--no-ftp] |')
				echo '    '$(eval_gettext ' --lamp|--c5|--concrete5|--concrete|')
				echo '    '$(eval_gettext ' --durupal|--drupal10|--drupal11]')
				echo '    '$(eval_gettext '[--nginx|--httpd]')
				echo '    '$(eval_gettext ' --nginx1.28|--nginx128|')
				echo '    '$(eval_gettext ' --nginx1.29|--nginx129|--nginx=version]')
				echo '    '$(eval_gettext '[--http-port port][--tls-port port]')
				echo '    '$(eval_gettext ' --php8.2|--php82|')
				echo '    '$(eval_gettext ' --php8.3|--php83|')
				echo '    '$(eval_gettext ' --php8.4|--php84|')
				echo '    '$(eval_gettext '[--php8.5|--php85|--php=version]')
				echo '    '$(eval_gettext '[--dbsystem mysql|mariadb]')
				echo '    '$(eval_gettext ' --mariadb10.6|--mariadb106|')
				echo '    '$(eval_gettext ' --mariadb10.11|--mariadb1011|')
				echo '    '$(eval_gettext ' --mariadb11.4|--mariadb114]')
				echo '    '$(eval_gettext ' --mariadb11.8|--mariadb118]')
				echo '    '$(eval_gettext '[--dbhost host]')
				echo '    '$(eval_gettext '[--dbport port]')
				echo '    '$(eval_gettext '[--dbrootpass pasword')
				echo '    '$(eval_gettext '[--dbname dbname]')
				echo '    '$(eval_gettext '[--dbuser username]')
				echo '    '$(eval_gettext '[--dbpass password]')
				;;
			config)
				echo $(eval_gettext 'config command ')
				echo '    '$(eval_gettext 'bcache [on|off]')
				echo '    '$(eval_gettext 'fcache [on|off]')
				echo '    '$(eval_gettext 'pull')
				echo '    '$(eval_gettext 'push')
				echo '    '$(eval_gettext 'dbdump [file]')
				echo '    '$(eval_gettext 'dbrestore [file]')
				echo '    '$(eval_gettext 'backup')
				echo '    '$(eval_gettext 'restore')
				echo '    '$(eval_gettext '[--help|help]')
				;;
			ssl)
				echo $(eval_gettext 'ssl [options]')
				echo '    '$(eval_gettext '[--cert file --key file]')
				echo '    '$(eval_gettext '[--redirect|--noredirect]')
				echo '    '$(eval_gettext '[--hsts  [on|off]]')
				echo '    '$(eval_gettext '[--oscp  [on|off]]')
				echo '    '$(eval_gettext '[--ct  [on|off]]')
				echo '    '$(eval_gettext '[--help|help]')
                ;;
			remove)
				echo $(eval_gettext 'remove [-y] [target]')
				;;
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
	k_target > /dev/null
	case $_cmd in
	'start'|'stop'|'ps')
		cd "$TARGETDIR" && k_compose $_cmd $_service
		;;
	'restart')
		cd "$TARGETDIR" && k_compose down && k_compose up -d
		;;
	'status')
		cd "$TARGETDIR" && k_compose ps $_service
		;;
	*)
	esac

}

function k_remove() {
	k_target $2

	local _PWD=$(pwd)
	cd "$TARGETDIR" \
	&& k_compose down -v \
	&& cd .. \
	&& rm -rf "$TARGETDIR" \
	&& ([ -d "$_PWD" ] && cd "$_PWD" || true)
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
	k_is_tty && echo -e "\e[31m${OUT}\e[m" || echo "$OUT" 1>&2
}

function k_print_green () {
	local OUT="${1}"
	k_is_tty && echo -e "\e[32m${OUT}\e[m" || echo "$OUT" 1>&2
}

function k_print_yellow () {
	local OUT="${1}"
	k_is_tty && echo -e "\e[33m${OUT}\e[m" || echo "$OUT" 1>&2
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

