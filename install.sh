#!

for r in mkdir git  ; do
	which $r 2>&1 > /dev/null \
	&& (echo -n "found "; which $r)\
	|| echo "you needs installing $r."
done

KUSANAGIDIR=$HOME/.kusanagi
mkdir -p $KUSANAGIDIR && cd $KUSANAGIDIR
git clone https://github.com/prime-strategy/kusanagi-docker.git $KUSANGIDIR

for r in $(cat lib/.requires) ; do
	which $r 2>&1 > /dev/null \
	&& (echo -n "found "; which $r)\
	|| echo "you needs installing $r."
done
