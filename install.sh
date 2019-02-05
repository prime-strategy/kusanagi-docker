#!/bin/bash

for r in mkdir git  ; do
	which $r 2>&1 > /dev/null \
	&& (echo -n "found "; which $r)\
	|| echo "you needs installing $r."
done

export KUSANAGIDIR=$HOME/.kusanagi
mkdir -p $KUSANAGIDIR && cd $KUSANAGIDIR
git clone $@ https://github.com/prime-strategy/kusanagi-docker.git $KUSANGIDIR
KUSANAGILIBDIR=$KUSANAGIDIR/lib
source ./update_version/sh

for r in $(cat lib/.requires) ; do
	which $r 2>&1 > /dev/null \
	&& (echo -n "found "; which $r)\
	|| echo "you needs installing $r."
done
