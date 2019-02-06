#!/bin/bash

function kusanagi_version {
	local _kusanagi=$1
	local _ver=$(git ls-remote -t https://github.com/prime-strategy/$_kusanagi.git 2>&1 |awk '{print $2}' | awk -F/ '/^[0-9\.\-a-zA-Z\/]+$/ {print $NF}'|sort -rV | head -1)
	echo ${_ver:-latest}
}

function mariadb_version {
	local _ver=$(curl -L https://raw.githubusercontent.com/docker-library/mariadb/master/10.4/Dockerfile 2> /dev/null  | awk -F'[ +~:]' '/ENV +MARIADB_VERSION/ {printf "%s-%s\n",$4,$6}')
	echo ${_ver:-latest}
}

function postgresql_version {
	local _ver=$(curl -L  https://raw.githubusercontent.com/docker-library/postgres/master/11/alpine/Dockerfile 2> /dev/null | awk '/ENV +PG_VERSION/ {print $NF"-alpine"}')
	echo ${_ver:-latest}
}

function wpcli_version {
	local _ver=$(curl -L https://raw.githubusercontent.com/docker-library/wordpress/master/php7.3/cli/Dockerfile 2> /dev/null | awk '/ENV +WORDPRESS_CLI_VERSION/ {print $NF}')
	echo ${_ver:-latest}
}

function certbot_version {
	local _ver=$(git ls-remote -t https://github.com/certbot/certbot.git |awk '{print $2}' | awk -F/ '/^[0-9\.\-a-zA-Z\/]+$/ {print $NF}'|sort -Vr | head -1)
	echo ${_ver:-latest}
}

KUSANAGI_NGINX_IMAGE=primestrategy/kusanagi-nginx:$(kusanagi_version kusanagi-nginx)
KUSANAGI_HTTPD_IMAGE=primestrategy/kusanagi-httpd:$(kusanagi_version kusanagi-httpd)
KUSANAGI_PHP7_IMAGE=primestrategy/kusanagi-http:$(kusanagi_version kusanagi-php7)
KUSANAGI_MARIADB_IMAGE=primestrategy/kusanagi-mariadb:$(kusanagi_version kusanagi-mariadb)
KUSANAGI_FTPD_IMAGE=primestrategy/kusanagi-ftpd:$(kusanagi_version kusanagi-ftpd)
POSTGRESQL_IMAGE=postgres:$(postgresql_version)
WPCLI_IMAGE=wordpress:cli-$(wpcli_version)-php7.3
CERTBOT_IMAGE=certbot/certbot:$(certbot_version)

cat <<EOF > ${KUSANAGILIBDIR:-.}/.version
KUSANAGI_NGINX_IMAGE=$KUSANAGI_NGINX_IMAGE
KUSANAGI_HTTPD_IMAGE=$KUSANAGI_HTTPD_IMAGE
KUSANAGI_PHP7_IMAGE=$KUSANAGI_PHP7_IMAGE
KUSANAGI_MARIADB_IMAGE=$KUSANAGI_MARIADB_IMAGE
KUSANAGI_FTPD_IMAGE=$KUSANAGI_FTPD_IMAGE
POSTGRESQL_IMAGE=$POSTGRESQL_IMAGE
WPCLI_IMAGE=$WPCLI_IMAGE
CERTBOT_IMAGE=$CERTBOT_IMAGE
EOF
