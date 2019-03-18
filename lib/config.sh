#
# KUSANAGI functions for kusanagi-docker
# (C)2019 Prime-Strategy Co,Ltd
# Licenced by GNU GPL v2
#


function k_bcache () {
	shift
	local cmd=$1
	k_target > /dev/null || return 1
	k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	if [ $KUSANAGI_PROVISION != "wp" ] ; then
		k_print_error $(eval_gettext "WordPress is not provision.")
		return 1
	fi

	local _ret=$(docker-compose run --rm -w $BASEDIR/tools config ./bcache.sh $cmd 2> /dev/null | sed 's/\r//g')
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
	k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	case $cmd in
	on)
		k_rewrite DONOT_USE_FCACHE 0 $TARGETDIR/.kusanagi.httpd
		docker-compose up -d
		k_print_info $(eval_gettext "fcache is on")
		;;
	off)
		k_rewrite DONOT_USE_FCACHE 1 $TARGETDIR/.kusanagi.httpd
		docker-compose up -d
		k_print_info $(eval_gettext "fcache is off")
		;;
	clear)
		docker-compose run --rm -w $BASEDIR/tools config ./fcache.sh clear $* 2> /dev/null 
		if [ $? -ne 0 ] ; then
			k_print_error $(eval_gettext "fcache can not clear")
			return 1
		else
			k_print_info $(eval_gettext "fcache is clear")
		fi
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

function k_naxsi() {
	shift
	local cmd=$1
	k_target  > /dev/null || return 1
	k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	case $cmd in
	on)
		k_rewrite DONOT_USE_NAXSI 0 $TARGETDIR/.kusanagi.httpd
		docker-compose up -d
		k_print_info $(eval_gettext "naxsi is on")
		;;
	off)
		k_rewrite DONOT_USE_NAXSI 1 $TARGETDIR/.kusanagi.httpd
		docker-compose up -d
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
	k_machine > /dev/null || return 1

	k_configcmd $DOCUMENTROOT ${_opts[@]}
}
	
function k_content() {
	local _cmd=$1
	shift
	local _opts=($@)
	k_target  > /dev/null || return 1
	k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	CONTENTDIR=$TARGETDIR/contents 
	
	if ! [ -d $CONTENTDIR ] ; then
	       	mkdir -p $CONTENTDIR
		git init -q
	fi
	case $_cmd in
	pull|backup)
		k_configcmd $BASEDIR tar cf /home/kusanagi/$PROFILE.tar .
		docker cp ${PROFILE}_httpd:/home/kusanagi/$PROFILE.tar .
		k_configcmd $BASEDIR rm //home/kusanagi/$PROFILE.tar
		tar xf $PROFILE.tar -C $CONTENTDIR
		rm $PROFILE.tar
		#git commit -a -m "pull at "$(date +%Y%m%dT%H%M%S%z)
		;;
	push|restore)
		#git commit -a -m "push at "$(date +%Y%m%dT%H%M%S%z)
		tar cf - -C $CONTENTDIR --exclude-from=$TARGETDIR/.gitignore . | docker-compose run --rm -w $BASEDIR -u 0 config tar xf - --same-owner
		return 0
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
	k_target  > /dev/null || return 1
	k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db
	CONTENTDIR=$TARGETDIR/contents 

	if [ $KUSANAGI_PROVISION = wp ] ; then
		k_configcmd $DOCUMENTROOT db export - > $CONTENTDIR/dbdump 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			k_configcmd / mysqldump -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME > $CONTENTDIR/dbdump
			;;
		pgsql)
			k_configcmd / pg_dump $DBHOST $DBNAME > $CONTENTDIR/dbdump
			;;
		*)
			;;
		esac
	fi
}


function k_dbrestore() {
	shift
	k_target  > /dev/null || return 1
	k_machine > /dev/null || return 1
	source $TARGETDIR/.kusanagi
	source $TARGETDIR/.kusanagi.db
	CONTENTDIR=$TARGETDIR/contents 

	if [ $KUSANAGI_PROVISION = wp ] ; then
		k_configcmd $DOCUMENTROOT db import - < $CONTENTDIR/dbdump 
	else
		[[ $DBHOST =~ ^localhost ]] && DBHOST= || DBHOST="-h $DBHOST"
		case $KUSANAGI_DB_SYSTEM in
		mysql)
			k_configcmd / mysql -u$DBUSER $DBHOST -p"$DBPASS" $DBNAME < $CONTENTDIR/dbdump
			;;
		pgsql)
			k_configcmd / pg_restore $DBHOST -d $DBNAME < $CONTENTDIR/dbdump
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
		k_fcache $@
		;;
	naxsi) #[on|off]
		k_naxsi $@
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
