#!/bin/sh

cmd=$1
if [ $KUSANAGI_PROVISION != "wp" ] ; then
	exit 1
fi

test -f ../DocumentRoot/wp-config.php && _dir=../Documentroot || \
 test -f ../wp-config.php && _dir=..
[ "x$_dir" = "x" ] && exit 1

case $cmd in
on)
	sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $_dir/wp-config.php
	sed -i 's/^\s*[#\/]\+\s*define\s*(\s*\'\''WP_CACHE\'\''.*$/define(\'\''WP_CACHE\'\'', true);/' $_dir/wp-config.php
	echo on
	;;
off)
	sed -i 's/^\s*define\s*(\s*\'\''WP_CACHE\'\''.*$/#define(\'\''WP_CACHE\'\'', true);/' $_dir/wp-config.php
	echo off
	;;
clear)
	php bcache.clear.php 
	echo clear
	;;
*)
	RET=`grep -e "^\s*define\s*(\s*'WP_CACHE'" $_dir/wp-config.php | grep true`
	if [ "x$RET" = "x" ]; then
		echo off
	else
		echo on
	fi
	;;
esac
