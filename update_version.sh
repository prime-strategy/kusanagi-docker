#!/bin/bash

function filter_version {
       local PYTHON=$(type python3 | cut -d' ' -f 3)
       PYTHON=${PYTHON:-$(type python | cut -d ' ' -f 3)}
       ${PYTHON} -c 'import sys
import json
input = json.load(sys.stdin)
if "results" not in input.keys():
	exit(0)
for i in input["results"]:
	if "name" in i.keys():
		print(i["name"])'
}

DOCKER_REPO=https://registry.hub.docker.com/v2/repositories
function docker_repo_tag {
	curl -s $DOCKER_REPO/${1}/tags\?page_size=10000 | filter_version | sort -Vr
}

function k_version {
	local _kusanagi=kusanagi-$1
	local _version=$2
	local _ver
	if [ -z "$_version" ] ; then
		_ver=$(docker_repo_tag primestrategy/${_kusanagi} | \
			   grep -v latest | head -1)
	else
		_ver=$(docker_repo_tag primestrategy/${_kusanagi} | \
			   grep "^$_version"  | head -1)
	fi
	echo ${_ver:-latest}
}

function mariadb_version {
	local _version=$1
	local _ver
	if [ -z "$_version" ] ; then
		_ver=$(docker_repo_tag library/mariadb | \
		fgrep . | head -1)
    else
		 _ver=$(docker_repo_tag library/mariadb | \
		grep "^$_version" | grep -v -e latest -e ubi | head -1)
	fi
	echo ${_ver:-latest}
}
function postgresql_version {
	local _ver=$(docker_repo_tag library/postgres | \
		fgrep . | grep -v -e latest -e beta | head -1)
	echo ${_ver:-latest}
}

function wpcli_version {
	local _ver=$(docker_repo_tag library/wordpress | \
		grep -Ee '^cli-[0-9].*$' | grep -v -e latest -e beta | head -1)
	echo ${_ver:-cli}
}

function certbot_version {
	local _ver=$(docker_repo_tag certbot/certbot | \
		grep -v -e latest -e beta | head -1)
	echo ${_ver:-latest}
}

PS=primestrategy/kusanagi
KUSANAGIDIR=${KUSANGIDIR:-$HOME/.kusanagi}
KUSANAGILIBDIR=$KUSANAGIDIR/lib

cat <<EOF > ${KUSANAGILIBDIR:-.}/image_versions
KUSANAGI_NGINX126_IMAGE=${PS}-nginx:$(k_version nginx 1.26)
KUSANAGI_NGINX127_IMAGE=${PS}-nginx:$(k_version nginx 1.27)
KUSANAGI_NGINX128_IMAGE=${PS}-nginx:$(k_version nginx 1.28)
KUSANAGI_NGINX_IMAGE=${PS}-nginx:$(k_version nginx 1.27)
KUSANAGI_HTTPD_IMAGE=${PS}-httpd:$(k_version httpd)
KUSANAGI_PHP81_IMAGE=${PS}-php:$(k_version php 8.1)
KUSANAGI_PHP82_IMAGE=${PS}-php:$(k_version php 8.2)
KUSANAGI_PHP83_IMAGE=${PS}-php:$(k_version php 8.3)
KUSANAGI_PHP84_IMAGE=${PS}-php:$(k_version php 8.4)
KUSANAGI_PHP_IMAGE=${PS}-php:$(k_version php 8.1)
KUSANAGI_MYSQL105_IMAGE=mariadb:$(mariadb_version 10.5)
KUSANAGI_MYSQL106_IMAGE=mariadb:$(mariadb_version 10.6)
KUSANAGI_MYSQL1011_IMAGE=mariadb:$(mariadb_version 10.11)
KUSANAGI_MYSQL114_IMAGE=mariadb:$(mariadb_version 11.4)
KUSANAGI_MYSQL_IMAGE=mariadb:$(mariadb_version 10.6)
KUSANAGI_CONFIG_IMAGE=${PS}-config:$(k_version config)
KUSANAGI_FTPD_IMAGE=${PS}-ftpd:$(k_version ftpd)
POSTGRESQL_IMAGE=postgres:$(postgresql_version)
WPCLI_IMAGE=wordpress:$(wpcli_version)
CERTBOT_IMAGE=certbot/certbot:$(certbot_version)
EOF
