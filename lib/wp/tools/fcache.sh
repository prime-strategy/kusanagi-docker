#!/bin/sh

if [ "x$1" = "x" ] ; then
	FILES=`find /var/cache/nginx/wordpress/ |xargs grep "KEY $2"`
else
	FILES=`find /var/cache/nginx/wordpress/ |xargs grep "KEY $2" | grep $1`  
fi
[ "x$FILES" = "x" ] || ( echo "$FILES" | xargs rm )
