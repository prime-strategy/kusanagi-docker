#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#


function b_cache () {
	shift
	local cmd=$1
	k_target $2 || return false
	k_machine || return false
	source $TARGETDIR/.kusanagi
	if [ $KUSANAGI_PROVISION = "wp" ] ; then
		k_print_error $(eval_gettext "WordPress is not provision.")
		return false
	fi

	WPCONFIG=$(k_wpconfig)
	case $cmd in
	on)
		$CONFIGCMD sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG	
		$CONFIGCMD sed -i "s/^\s*[#\/]\+\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG
		;;
	off)
		$CONFIGCMD sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/#define('WP_CACHE', true);/" $WPCONFIG
		;;
	clear)
                local RET=$($CONFIGCMD grep -e "^[[:space:]]*define[[:space:]]*([[:space:]]*'WP_CACHE'" $WPCONFIG | grep 'true')
		if [ "$RET" ]; then
			k_print_info $(eval_gettext "bcache is on")
		else
			k_print_info $(eval_gettext "bcache is off")
		fi
		;;
	*)
	esac
}

function k_fcache() {
	shift
	local cmd=$1
	k_target $2 || return false
	k_machine || return false
	source $TARGETDIR/.kusanagi
	case $cmd in
	on)
		k_rewrite DONOT_USE_FCACHE 0 $TARGETDIR/.kusanagi.httpd
		docker-compose up httpd -d
		;;
	off)
		k_rewrite DONOT_USE_FCACHE 1 $TARGETDIR/.kusanagi.httpd
		docker-compose up httpd -d
		;;
	*)
		local _t=$(grep DONOT_USE_FCACHE= $TARGETDIR/.kusanagi.httpd)
		if [ "${_t##*=}" -eq 0 ]; then
			k_print_info $(eval_gettext "fcache is on")
		else
			k_print_info $(eval_gettext "fcache is off")
		fi
		;;
	esac
}

function k_wp() {
	shift
	local _opts=($@)
	local _target=
	if [ ${#_opts[@]} -gt 0 ] ; then
		_target=${_opts[-1]}
		unset _opts[-1]
	fi
	k_target $_target || return false
	k_machine || return false

	$CONFIGCMD ${_opts[@]}
}
	
function k_content() {
	local _cmd=$1
	shift
	local _opts=($@)
	local _target=
	if [ ${#_opts[@]} -gt 0 ] ; then
		_target=${_opts[-1]}
		unset _opts[-1]
	fi
	k_target $_target || return false
	k_machine || return false
	source $TARGETDIR/.kusanagi
	
	if ! [ -d $CONTENTDIR ] ; then
	       	mkdir -p $CONTENTDIR
		(cd $CONTENTDIR; git init -q )
	fi
	case $_cmd in
	pull|backup)
		$CONFIGCMD tar cf - -C $BASEDIR . | tar xf - -C $CONTENTDIR
		;;
	push|restore)
		tar cf - -C $CONTENTDIR --exclude-from=$CONTENTDIR/.gitignore . | $CONFIGCMD tar xf - -C $BASEDIR 
		;;
	commit)
		(cd $CONTENTDIR; git commit ${_opts[@]})
		;;
	checkout)
		(cd $CONTENTDIR; git checkout ${_opts[@]})
		;;
	tag)
		(cd $CONTENTDIR; git tag ${_opts[@]})
		;;
	log)
		(cd $CONTENTDIR; git log ${_opts[@]})
		;;
	*)
	esac

}

function k_dbdump() {
	shift
	k_target $1 || return false
	k_machine || return false
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db

	if [ $KUSANAGI_PROVISION = wp ] ; then
		$CONFIGCMD db export > $CONTENTDIR/dbdump 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			$CONFIGCMD mysqldump -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME > $CONTENTDIR/dbdump
			;;
		pgsql)
			$CONFIGCMD pg_dump $DBHOST $DBNAME > $CONTENTDIR/dbdump
			;;
		*)
			;;
		esac
	fi
}


function k_dbrestore() {
	shift
	k_target $1 || return false
	k_machine || return false
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db
	CONTENTDIR=$TARGETDIR/contents 

	if [ $KUSANAGI_PROVISION = wp ] ; then
		$CONFIGCMD db import < $CONTENTDIR/dbdump 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			$CONFIGCMD mysql -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME < $CONTENTDIR/dbdump
			;;
		pgsql)
			$CONFIGCMD pg_restore $DBHOST -d $DBNAME < $CONTENTDIR/dbdump
			;;
		*)
			;;
		esac
	fi
}

function k_config () {
	# sub command
	case "$1" in
	bcache)# [on|off]
		k_bcache $@
		;;
	fcache) #[on|off]
		k_bcache $@
		;;
	pull|push|tag|log|commit|backup|restore)
		k_content $@
		;;
	dbdump)
		k_dbdump $@
		;;
	dbrestore)
		k_dbrestore $@
		;;
	*)
		k_print_error config $OPT $(eval_gettext "is unknown subcommand.")
		false
	esac
}
