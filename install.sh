#!/bin/bash

DOCKER_REPO=https://registry.hub.docker.com/v1/repositories
function docker_repo_tag {
	curl -s $DOCKER_REPO/${1}/tags | tr , "\n" | \
		awk -F\" '/name/ {print $4}'
}
function k_version {
	local _kusanagi=kusanagi-$1
	local _ver=$(docker_repo_tag primestrategy/${_kusanagi} | \
		grep -v latest | sort -Vr | head -1)
	echo ${_ver:-latest}
}


version=$(k_version docker)
for r in mkdir curl tar gettext msgfmt envsubst ; do
	which $r 2>&1 > /dev/null \
		|| (echo -e "\e[31m"you needs installing $r."\e[m"; exit 1)
done

export KUSANAGIDIR=$HOME/.kusanagi
echo -e "\e[32m"cloning kusanagi-docker commands"\e[m" 1>&2
branch=${1:-$version}
if [ -d $KUSANAGIDIR ] ; then
	(cd $KUSANAGIDIR && git pull && git checkout --tags $version)
else	
	git clone -b $branch https://github.com/prime-strategy/kusanagi-docker.git $KUSANAGIDIR
fi
echo $version > $KUSANAGIDIR/.version
KUSANAGILIBDIR=$KUSANAGIDIR/lib
source $KUSANAGIDIR/update_version.sh
[ -d $KUSANAGIDIR/lib/locale/ja/LC_MESSAGES ] || mkdir -p $KUSANAGIDIR/lib/locale/ja/LC_MESSAGES
msgfmt -f -o $KUSANAGIDIR/lib/locale/ja/LC_MESSAGES/kusanagi-docker.mo $KUSANAGIDIR/lib/locale/kusanagi-docker.po

echo -e "\e[32m"check commands requires kusanagi-docker"\e[m" 1>&2
for r in $(cat $KUSANAGILIBDIR/.requires) ; do
	which $r 2>&1 > /dev/null \
	|| which ${r}.exe 2>&1 > /dev/null \
	|| echo -e "\e[31myou needs installing $r.\e[m"
done
echo -e "\e[32m"kusanagi-docker command install completes."\e[m"
echo -e "\e[32m"Please add these line to .bashrc or .zshrc"\e[m"
echo export PATH=$KUSANAGIDIR/bin:\$PATH
