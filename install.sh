#!/bin/bash

for r in mkdir curl tar gettext msgfmt  ; do
	which $r 2>&1 > /dev/null \
		|| (echo -e "\e[31m"you needs installing $r."\e[m"; exit 1)
done

export KUSANAGIDIR=$HOME/.kusanagi
echo -e "\e[32m"cloning kusanagi-docker commands"\e[m" 1>&2
branch=${1:-master}
git clone -b $branch https://github.com/prime-strategy/kusanagi-docker.git $KUSANAGIDIR
(cd $KUSANAGIDIR; git show -s --format=%D) > $KUSANAGIDIR/.version
rm -rf $KUSANAGIDIR/.git
KUSANAGILIBDIR=$KUSANAGIDIR/lib
source $KUSANAGIDIR/update_version.sh
mkdir -p $KUSANAGIDIR//lib/locale/ja/LC_MESSAGES
msgfmt -f -o $KUSANAGIDIR/lib/locale/ja/LC_MESSAGES/kusanagi-docker.mo $KUSANAGIDIR/lib/locale/kusanagi-docker.po

echo -e "\e[32m"check commands requires kusanagi-docker"\e[m" 1>&2
for r in $(cat $KUSANAGILIBDIR/.requires) ; do
	which $r 2>&1 > /dev/null \
	|| echo -e "\e[31myou needs installing $r.\e[m"
done
echo -e "\e[32m"kusanagi-docker command install completes."\e[m"
echo -e "\e[32m"Please add these line to .bashrc or .zshrc"\e[m"
echo export PATH=$KUSANAGIDIR/bin:\$PATH
