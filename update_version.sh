#!/bin/bash

function kusanagi_version {
	local _kusanagi=$1
	local _ver=$(git ls-remote -t https://github.com/prime-strategy/$_kusanagi.git 2>&1 |awk '{print $2}' | awk -F/ '/^[0-9\.\-a-zA-Z\/]+$/ {print $NF}'|sort -rV | head -1)
	echo ${_ver:-latast}
}

function mariadb_version {
	local _ver=$(curl -L https://raw.githubusercontent.com/docker-library/mariadb/master/10.4/Dockerfile 2> /dev/null  | awk -F'[ +~:]' '/ENV +MARIADB_VERSION/ {printf "%s-%s\n",$4,$6}')
	echo ${_ver:-latast}
}

function postgresql_version {
	local _ver=$(curl -L  https://raw.githubusercontent.com/docker-library/postgres/master/11/alpine/Dockerfile 2> /dev/null | awk '/ENV +PG_VERSION/ {print $NF"-alpine"}')
	echo ${_ver:-latast}
}

function wpcli_version {
	local _ver=$(curl -L https://raw.githubusercontent.com/docker-library/wordpress/master/php7.3/cli/Dockerfile 2> /dev/null | awk '/ENV +WORDPRESS_CLI_VERSION/ {print $NF}')
	echo ${_ver:-latast}
}

function certbot_version {
	local _ver=$(git ls-remote -t https://github.com/certbot/certbot.git |awk '{print $2}' | awk -F/ '/^[0-9\.\-a-zA-Z\/]+$/ {print $NF}'|sort -Vr | head -1)
	echo ${_ver:-latast}
}

KUSANAGI_NGINX_VERSION=$(kusanagi_version kusanagi-nginx)
KUSANAGI_HTTPD_VERSION=$(kusanagi_version kusanagi-httpd)
KUSANAGI_PHP7_VERSION=$(kusanagi_version kusanagi-php7)
KUSANAGI_MARIADB_VERSION=$(kusanagi_version kusanagi-mariadb)
KUSANAGI_FTPD_VERSION=$(kusanagi_version kusanagi-ftpd)
POSTGRESQL_VERSION=$(postgresql_version)
WPCLI_VERSION=$(wpcli_version)
CERTBOT_VERSION=$(certbot_version)

cat <<EOF > ${KUSANAGIDIR:-.}/.version
KUSANAGI_NGINX_VERSION=$KUSANAGI_NGINX_VERSION
KUSANAGI_HTTPD_VERSION=$KUSANAGI_HTTPD_VERSION
KUSANAGI_PHP7_VERSION=$KUSANAGI_PHP7_VERSION
KUSANAGI_MARIADB_VERSION=$KUSANAGI_MARIADB_VERSION
KUSANAGI_FTPD_VERSION=$KUSANAGI_FTPD_VERSION
POSTGRESQL_VERSION=$POSTGRESQL_VERSION
WPCLI_VERSION=$WPCLI_VERSION
CERTBOT_VERSION=$CERTBOT_VERSION
EOF
