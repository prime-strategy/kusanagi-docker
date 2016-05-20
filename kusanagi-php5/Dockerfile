#//----------------------------------------------------------------------------
#// KUSANAGI C2D (kusanagi-php5)
#//----------------------------------------------------------------------------
FROM php:5.6.20-fpm-alpine
MAINTAINER d-higuchi@creationline.com

RUN apk update \
	&& apk add mysql \
	&& docker-php-ext-install mysqli
