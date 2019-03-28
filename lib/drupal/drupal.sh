
function deploy_drupal() {
	local _ver=$1
	[ $_ver -eq 7 -o $_ver -eq 8 ] || _ver=8
	WORKDIR=$(mktemp -d)
	cd $WORKDIR
	local PROJ="project/drupal/releases"
	local REL=$(wget -O - https://www.drupal.org/$PROJ/ 2> /dev/null | egrep '<h2><a href="/'$PROJ'/'$_ver'\.[0-9]+\.[0-9]+">' | awk -F\" 'NR==1 {print $2}')
	[ "x$REL" = "x" ] && REL=$(wget -O - https://www.drupal.org/$PROJ/ 2> /dev/null | egrep '<h2><a href="/'$PROJ'/'$_ver'\.[0-9]+">' | awk -F\" 'NR==1 {print $2}')
	local VER=$(basename $REL)

	wget https://ftp.drupal.org/files/projects/drupal-${VER}.tar.gz
	tar xf drupal-${VER}.tar.gz
	mv drupal-${VER}/* drupal-${VER}/.[^.]* $DOCUMENTROOT
	if [ $_ver -eq 7 ] ; then
		wget https://ftp.drupal.org/files/projects/l10n_update-7.x-2.2.tar.gz
		tar xf l10n_update-7.x-2.2.tar.gz -C $DOCUMENTROOT/sites/all/modules/
	fi
	cd $DOCUMENTROOT

	rm -rf $WORKDIR

	chown -R 1000:1001 /home/kusanagi/$PROFILE
	cp sites/default/default.settings.php sites/default/settings.php
	chown -R 1000:1001 sites/default/
	chmod -R g+w sites/default/

	# create after_install shell script
	cat > ../after_install.sh <<EOF
#!

chmod -R g-w $DOCUMENTROOT/sites
chmod -R g-w $DOCUMENTROOT/sites/default/
cat >> $DOCUMENTROOT/sites/default/settings.php <<EOL

\\\$settings['trusted_host_patterns'] = array(
    '^${FQDN//\./\\.}\$',
    '^localhost\$',
);
EOL
EOF

	chmod 700 ../after_install.sh
}

deploy_drupal $@
