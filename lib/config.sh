#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#


function b_cache () {
	shift
	local cmd=$1
	k_target $2 || return 1
	k_machine || return 1
	source $TARGETDIR/.kusanagi
	if [ $KUSANAGI_PROVISION = "wp" ] ; then
		k_print_error $(eval_gettext "WordPress is not provision.")
		return 1
	fi

	WPCONFIG=$(k_wpconfig)
	case $cmd in
	on)
		k_configcmd sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG	
		k_configcmd sed -i "s/^\s*[#\/]\+\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG
		;;
	off)
		k_configcmd sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/#define('WP_CACHE', true);/" $WPCONFIG
		;;
	clear)
                local RET=$(k_configcmd grep -e "^[[:space:]]*define[[:space:]]*([[:space:]]*'WP_CACHE'" $WPCONFIG | grep 'true')
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
	k_target $2 || return 1
	k_machine || return 1
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
	k_target $_target || return 1
	k_machine || return 1

	k_configcmd ${_opts[@]}
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
	k_target $_target || return 1
	k_machine || return 1
	source $TARGETDIR/.kusanagi
	CONTENTDIR=$TARGETDIR/contents 
	
	if ! [ -d $CONTENTDIR ] ; then
	       	mkdir -p $CONTENTDIR
		git init -q
	fi
	case $_cmd in
	pull|backup)
		k_configcmd tar cf $BASEDIR/../content.tar -C $BASEDIR .
		docker cp ${PROFILE}_httpd:$BASEDIR/../content.tar .
		k_configcmd rm $BASEDIR/../content.tar
		tar xf content.tar -C $CONTENTDIR
		rm content.tar
		#git commit -a -m "pull at "$(date +%Y%m%dT%H%M%S%z)
		;;
	push|restore)
		#git commit -a -m "push at "$(date +%Y%m%dT%H%M%S%z)
		tar cf - -C $CONTENTDIR --exclude-from=$CONTENTDIR/.gitignore . | k_configcmd tar xf - -C $BASEDIR 
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
	k_target $1 || return 1
	k_machine || return 1
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db
	CONTENTDIR=$TARGETDIR/contents 

	if [ $KUSANAGI_PROVISION = wp ] ; then
		k_configcmd db export > $CONTENTDIR/dbdump 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			k_configcmd mysqldump -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME > $CONTENTDIR/dbdump
			;;
		pgsql)
			k_configcmd pg_dump $DBHOST $DBNAME > $CONTENTDIR/dbdump
			;;
		*)
			;;
		esac
	fi
}


function k_dbrestore() {
	shift
	k_target $1 || return 1
	k_machine || return 1
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db
	CONTENTDIR=$TARGETDIR/contents 

	if [ $KUSANAGI_PROVISION = wp ] ; then
		k_configcmd db import < $CONTENTDIR/dbdump 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			k_configcmd mysql -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME < $CONTENTDIR/dbdump
			;;
		pgsql)
			k_configcmd pg_restore $DBHOST -d $DBNAME < $CONTENTDIR/dbdump
			;;
		*)
			;;
		esac
	fi
}

function k_config () {
	shift
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
