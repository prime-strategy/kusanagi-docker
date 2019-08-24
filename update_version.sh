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

function mariadb_version {
	local _ver=$(docker_repo_tag mariadb | \
		fgrep . | sort -Vr | head -1)
	echo ${_ver:-latest}
}
function postgresql_version {
	local _ver=$(docker_repo_tag postgres | \
		fgrep . | grep -v -e latest -e beta | sort -Vr | head -1)
	echo ${_ver:-latest}
}

function wpcli_version {
	local _ver=$(docker_repo_tag wordpress | \
		grep -Ee '^cli-.*$' | grep -v -e latest -e beta | \
		sort -r | head -1)
	echo ${_ver:-latest}
}

function certbot_version {
	local _ver=$(docker_repo_tag certbot/certbot | \
		grep -v -e latest -e beta | sort -Vr | head -1)
	echo ${_ver:-latest}
}

PS=primestrategy/kusanagi
KUSANAGIDIR=${KUSANAGIDIR:=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)} # the default is path to install.sh
KUSANAGI_NGINX_IMAGE=${PS}-nginx:$(k_version nginx)
KUSANAGI_HTTPD_IMAGE=${PS}-httpd:$(k_version httpd)
KUSANAGI_PHP_IMAGE=${PS}-php:$(k_version php)
KUSANAGI_MYSQL_IMAGE=mariadb:$(mariadb_version)
KUSANAGI_CONFIG_IMAGE=${PS}-config:$(k_version config)
KUSANAGI_FTPD_IMAGE=${PS}-ftpd:$(k_version ftpd)
POSTGRESQL_IMAGE=postgres:$(postgresql_version)
WPCLI_IMAGE=wordpress:$(wpcli_version)
CERTBOT_IMAGE=certbot/certbot:$(certbot_version)

cat <<EOF > $KUSANAGIDIR/lib/image_versions
KUSANAGI_NGINX_IMAGE=$KUSANAGI_NGINX_IMAGE
KUSANAGI_HTTPD_IMAGE=$KUSANAGI_HTTPD_IMAGE
KUSANAGI_PHP_IMAGE=$KUSANAGI_PHP_IMAGE
KUSANAGI_MYSQL_IMAGE=$KUSANAGI_MYSQL_IMAGE
KUSANAGI_FTPD_IMAGE=$KUSANAGI_FTPD_IMAGE
KUSANAGI_CONFIG_IMAGE=$KUSANAGI_CONFIG_IMAGE
POSTGRESQL_IMAGE=$POSTGRESQL_IMAGE
WPCLI_IMAGE=$WPCLI_IMAGE
CERTBOT_IMAGE=$CERTBOT_IMAGE
EOF
