#//----------------------------------------------------------------------------
#// KUSANAGI C2D (kusanagi-php7)
#//----------------------------------------------------------------------------
FROM php:7.0.6-fpm-alpine
MAINTAINER d-higuchi@creationline.com

RUN apk update \
	&& apk add mysql \
	&& docker-php-ext-install mysqli opcache \
	&& pecl install apcu-5.1.3 \
	&& docker-php-ext-enable apcu \
	&& pecl install apcu_bc-1.0.3 \
	&& docker-php-ext-enable apc

COPY files/*.ini /usr/local/etc/php/conf.d/
RUN mkdir -p /etc/php.d/
COPY files/opcache*.blacklist /etc/php.d/
