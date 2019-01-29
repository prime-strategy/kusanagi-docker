#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#
GLOBAL_KUSANAGI_FILE=$HOME/.kusanagi/.kusanagi
LOCAL_KUSANAGI_FILE=.kusanagi

# make random username
function k_mkusername() {
	openssl rand -base64 1024 | fold -w 10 | egrep -e '^[a-zA-Z][a-zA-Z0-9]+$'| head -1
}

# make random password
function k_mkpasswd() {
	openssl rand -base64 1024 | fold -w 23 | egrep -e '^[!-/a-zA-Z0-9]+$'| head -1
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
			k_print_error "$_target "$(eval_gettext "not found.")
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
		k_print_error $(eval_gettext "TARGET has not been set.")
		false
	else
		export TARGETDIR=${TARGET##:*} TARGET=${TARGET%%:*}
		if [ "$_target" != "$TARGET" ] ; then
		#	k_rewrite TARGET "$TARGET:$TARGETDIR" $LOCAL_KUSANGI_FILE && \
			k_rewrite TARGET "$TARGET:$TARGETDIR" $GLOBAL_KUSANGI_FILE 
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
			eval $(grep ^MACHINE= "$GLOBAL_KUSANGI_FILE")
		else
			MACHINE=localhost
		fi
	elif [ "$_machine" != "localhost" ] ; then
		docker-machine ls | grep $_machine 2>&1 > /dev/null
		if [ $? -eq 1 ] ; then
			k_print_error $(eval_gettext $_machine " has not found.")
			return false
		fi
	fi

	if [ "$_machine" = "localhost" -o "$MACHINE" = "localhost" ] ; then
		[ "x$TARGETDIR" != "x" ] && \
		       	(cd $TARGETDIR && docker-compose ps) || docker ps
	else
		[ "x$TARGETDIR" != "x" ]  \
		       	&& (cd $TARGETDIR && \
		       		eval $(docker-machine env $_machine) && \
			       		docker-compose ps) \
			||  (eval $(docker-machine env $_machine) && docker ps) 
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
		echo $_var=$_val >> $_file
	fi
}

function check_status() {
	# 'Done.' Or 'Failed.' Is displayed by the return value of the previous command.
	# Please attach ${_RETURN} to the argument of exit.
	if [ "$?" -eq 0 ]; then
		echo $(eval_gettext "Done.")
		exit 0
	else
		echo $(eval_gettext "Failed.")
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
	cd $BASEDIR
	git tag -l | egrep '^[0-9\.\-]+$' | tail -1
	return 0
}

# display info message
function k_print_info () {
	k_print_green "INFO: $1"
}

# display error message
function k_print_error () {
	k_print_red "ERROR: $1"
}

# display notice message
function k_print_notice () {
	k_print_yellow "NOTICE: $1"
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

