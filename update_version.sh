#!/bin/bash

DOCKER_REPO=https://registry.hub.docker.com/v1/repositories
function docker_repo_tag {
	curl -s $DOCKER_REPO/${1}/tags | tr , "\n" | \
		awk -F\" '/name/ {print $4}'
}
function k_version {
	local _kusanagi=kusanagi-$1
	local _version=$2
	local _ver
	if [ -z "$_version" ] ; then
		_ver=$(docker_repo_tag primestrategy/${_kusanagi} | \
			   grep -v latest | sort -Vr | head -1)
	else
		_ver=$(docker_repo_tag primestrategy/${_kusanagi} | \
			   grep "^$_version" | sort -Vr | head -1)
	fi
	echo ${_ver:-latest}
}

function mariadb_version {
	local _version=$1
	local _ver
	if [ -z "$_version" ] ; then
		_ver=$(docker_repo_tag mariadb | \
		fgrep . | sort -Vr | head -1)
    else
		 _ver=$(docker_repo_tag mariadb | \
		grep "^$_version" | sort -Vr | head -1)
	fi
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
KUSANAGIDIR=${KUSANGIDIR:-$HOME/.kusanagi}
KUSANAGILIBDIR=$KUSANAGIDIR/lib

cat <<EOF > ${KUSANAGILIBDIR:-.}/image_versions
KUSANAGI_NGINX120_IMAGE=${PS}-nginx:$(k_version nginx 1.20)
KUSANAGI_NGINX121_IMAGE=${PS}-nginx:$(k_version nginx 1.21)
KUSANAGI_NGINX_IMAGE=${PS}-nginx:$(k_version nginx 1.21)
KUSANAGI_HTTPD_IMAGE=${PS}-httpd:$(k_version httpd)
KUSANAGI_PHP73_IMAGE=${PS}-php:$(k_version php 7.3)
KUSANAGI_PHP74_IMAGE=${PS}-php:$(k_version php 7.4)
KUSANAGI_PHP80_IMAGE=${PS}-php:$(k_version php 8.0)
KUSANAGI_PHP_IMAGE=${PS}-php:$(k_version php 7.4)
KUSANAGI_MYSQL103_IMAGE=mariadb:$(mariadb_version 10.3)
KUSANAGI_MYSQL104_IMAGE=mariadb:$(mariadb_version 10.4)
KUSANAGI_MYSQL105_IMAGE=mariadb:$(mariadb_version 10.5)
KUSANAGI_MYSQL_IMAGE=mariadb:$(mariadb_version 10.5)
KUSANAGI_CONFIG_IMAGE=${PS}-config:$(k_version config)
KUSANAGI_FTPD_IMAGE=${PS}-ftpd:$(k_version ftpd)
POSTGRESQL_IMAGE=postgres:$(postgresql_version)
WPCLI_IMAGE=wordpress:$(wpcli_version)
CERTBOT_IMAGE=certbot/certbot:$(certbot_version)
EOF
