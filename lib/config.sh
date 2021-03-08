#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#


function k_bcache () {
	shift
	local cmd=$1
	k_target > /dev/null || return 1
	#k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	if [ $KUSANAGI_PROVISION != "wp" ] ; then
		k_print_error $(eval_gettext "WordPress is not provision.")
		return 1
	fi

	local _ret=$(k_configcmd $BASEDIR/tools ./bcache.sh $cmd 2> /dev/null | sed 's/\r//g')
	if [ $? -ne 0 ] ; then
		k_print_error $(eval_gettext "WordPress is not provision.")
		return 1
	elif [ "$_ret" = "on" ]; then
		k_print_info $(eval_gettext "bcache is on")
	elif [ "$_ret" = "off" ]; then
		k_print_info $(eval_gettext "bcache is off")
	elif [ "$_ret" = "clear" ]; then
		k_print_info $(eval_gettext "bcache is clear")
	fi
}

function k_fcache() {
	shift
	local cmd=$1
	shift
	k_target  > /dev/null || return 1
	#k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	case $cmd in
	on)
		k_rewrite NO_USE_FCACHE 0 $TARGETDIR/.kusanagi.httpd
		k_compose stop php
		k_compose rm -f php
		k_compose up -d
		k_print_info $(eval_gettext "fcache is on")
		;;
	off)
		k_rewrite NO_USE_FCACHE 1 $TARGETDIR/.kusanagi.httpd
		k_compose stop php
		k_compose rm -f php
		k_compose up -d
		k_print_info $(eval_gettext "fcache is off")
		;;
	clear)
		k_configcmd $BASEDIR/tools config ./fcache.sh clear $* 2> /dev/null 
		if [ $? -ne 0 ] ; then
			k_print_error $(eval_gettext "fcache can not clear")
			return 1
		else
			k_print_info $(eval_gettext "fcache is clear")
		fi
		;;
	*)
		local _t=$(grep NO_USE_FCACHE= $TARGETDIR/.kusanagi.httpd)
		if [ "${_t##*=}" -eq 0 ]; then
			k_print_info $(eval_gettext "fcache is on")
		else
			k_print_info $(eval_gettext "fcache is off")
		fi
		;;
	esac
}

function k_naxsi() {
	shift
	local cmd=$1
	k_target  > /dev/null || return 1
	#k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	case $cmd in
	on)
		k_rewrite DONOT_USE_NAXSI 0 $TARGETDIR/.kusanagi.httpd
		k_compose stop php
		k_compose rm -f php
		k_compose up -d
		k_print_info $(eval_gettext "naxsi is on")
		;;
	off)
		k_rewrite DONOT_USE_NAXSI 1 $TARGETDIR/.kusanagi.httpd
		k_compose stop php
		k_compose rm -f php
		k_compose up -d
		k_print_info $(eval_gettext "naxsi is off")
		;;
	*)
		local _t=$(grep DONOT_USE_NAXSI= $TARGETDIR/.kusanagi.httpd)
		if [ "${_t##*=}" -eq 0 ]; then
			k_print_info $(eval_gettext "naxsi is on")
		else
			k_print_info $(eval_gettext "naxsi is off")
		fi
		;;
	esac
}


function k_wp() {
	shift
	local _opts=($@)
	local _target=
	k_target  > /dev/null || return 1
	#k_machine > /dev/null || return 1

	k_configcmd $DOCUMENTROOT ${_opts[@]}
}
	
function k_content() {
	local _cmd=$1
	shift
	local _opts=($@)
	k_target  > /dev/null || return 1
	#k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	CONTENTDIR=$TARGETDIR/contents 
	
	if ! [ -d $CONTENTDIR ] ; then
	       	mkdir -p $CONTENTDIR
		git init -q
	fi
	case $_cmd in
	pull|backup)
		k_configcmd $BASEDIR tar cf /home/kusanagi/$PROFILE.tar .
		docker cp ${PROFILE}_config:/home/kusanagi/$PROFILE.tar .
		k_configcmd $BASEDIR rm /home/kusanagi/$PROFILE.tar
		tar xf $PROFILE.tar -C $CONTENTDIR
		rm $PROFILE.tar
		[ $_cmd = "backup" ] && k_dbdump
		#git commit -a -m "pull at "$(date +%Y%m%dT%H%M%S%z)
		;;
	push|restore)
		#git commit -a -m "push at "$(date +%Y%m%dT%H%M%S%z)
		local is_dir=$(k_configcmd '/' test -d $BASEDIR ; echo $?)
		if [ $is_dir = 1 ] ; then
			k_configcmd_root '/' mkdir -p $BASEDIR
			k_configcmd_root '/home/kusanagi' chown -R 1000:1001 /home/kusanagi
		fi
		tar cf $PROFILE.tar -C $CONTENTDIR --exclude-from=$TARGETDIR/.gitignore .
		docker cp $PROFILE.tar ${PROFILE}_config:/home/kusanagi/
		rm $PROFILE.tar
		k_configcmd $BASEDIR tar xf /home/kusanagi/$PROFILE.tar
		k_configcmd $BASEDIR rm /home/kusanagi/$PROFILE.tar
		k_configcmd $BASEDIR chown -R kusanagi:www .
		[ $_cmd = "restore" ] && k_dbrestore
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
	local _file=${1:-dbdump}
	k_target  > /dev/null || return 1
	#k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db
	CONTENTDIR=$TARGETDIR/contents 

	if [ $KUSANAGI_PROVISION = wp ] ; then
		k_configcmd $DOCUMENTROOT db export - > $_file 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			k_configcmd / mysqldump -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME > $_file
			;;
		pgsql)
			k_configcmd / pg_dump $DBHOST $DBNAME > $_file
			;;
		*)
			;;
		esac
	fi
}


function k_dbrestore() {
	local _file=${1:-dbdump}
	k_target  > /dev/null || return 1
	#k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db
	CONTENTDIR=$TARGETDIR/contents 

	tar cf - $_file | k_configcmd $BASEDIR tar xf - 
	if [ $KUSANAGI_PROVISION = wp ] ; then
		k_configcmd $DOCUMENTROOT db import $BASEDIR/$_file 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			k_configcmd $BASEDIR mysqlimport -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME $_file
			;;
		pgsql)
			k_configcmd $BASEDIR pg_restore $DBHOST -d $DBNAME $_file
			;;
		*)
			;;
		esac
	fi
	k_configcmd $BASEDIR rm $_file 
}

function k_config () {
	# sub command
	case "$1" in
	bcache)# [on|off]
		k_bcache $@
		;;
	fcache) #[on|off]
		k_fcache $@
		;;
	naxsi) #[on|off]
		k_naxsi $@
		;;
	pull|push|tag|log|commit|backup|restore)
		k_content $1
		;;
	dbdump)
		k_dbdump $2
		;;
	dbrestore)
		k_dbrestore $2
		;;
	--help|help)
		k_helphelp config help
		return 0
		;;
	*)
		k_print_error config $OPT $(eval_gettext "is unknown subcommand.")
		return 1
	esac
}
