#//----------------------------------------------------------------------------
#// KUSANAGI C2D (kusanagi-nginx)
#//----------------------------------------------------------------------------
FROM centos:7
MAINTAINER d-higuchi@creationline.com

ENV KUSANAGI_VERSION		7.8.2-2
ENV KUSANAGI_WP_VERSION		4.5.2-1
ENV KUSANAGI_NGINX_VERSION	1.10.0-1
ENV KUSANAGI_LIBBROTLI_VERSION	1.0pre1-2
ENV KUSANAGI_OPENSSL_VERSION	1.0.2h-1

RUN groupadd -g 1000 www \
	&& groupadd -g 1001 kusanagi \
	&& useradd -d /home/httpd -c '' -s /bin/false -G www -M -u 1000 httpd \
	&& useradd -d /home/kusanagi -c '' -s /bin/bash -g kusanagi -G www -u 1001 kusanagi \
	&& chmod 755 /home/kusanagi

RUN \
	curl -fSL https://repo.prime-strategy.co.jp/rpm/noarch/kusanagi-${KUSANAGI_VERSION}.noarch.rpm -o kusanagi.rpm \
	&& curl -fSL https://repo.prime-strategy.co.jp/rpm/noarch/kusanagi-wp-${KUSANAGI_WP_VERSION}.noarch.rpm -o kusanagi-wp.rpm \
	&& curl -fSL https://repo.prime-strategy.co.jp/rpm/noarch/kusanagi-nginx-${KUSANAGI_NGINX_VERSION}.noarch.rpm -o kusanagi-nginx.rpm \
	&& curl -fSL https://repo.prime-strategy.co.jp/rpm/noarch/kusanagi-libbrotli-${KUSANAGI_LIBBROTLI_VERSION}.noarch.rpm -o kusanagi-libbrotli.rpm \
	&& curl -fSL https://repo.prime-strategy.co.jp/rpm/noarch/kusanagi-openssl-${KUSANAGI_OPENSSL_VERSION}.noarch.rpm -o kusanagi-openssl.rpm \
	&& rpm -Uvh --nodeps kusanagi.rpm kusanagi-openssl.rpm \
	&& yum localinstall -y kusanagi-wp.rpm kusanagi-nginx.rpm kusanagi-libbrotli.rpm \
	&& yum install -y wget openssl \
	&& rm -f kusanagi*.rpm \
	&& yum clean all

RUN mkdir -p /var/log/nginx /etc/nginx/conf.d /etc/httpd/conf.d \
	&& sed -i 's/^sed.*\/etc\/hosts/#sed/' /usr/lib/kusanagi/lib/virt.sh \
	&& sed -i 's/systemctl/\/bin\/true/g' /usr/lib/kusanagi/lib/virt.sh

VOLUME /home/kusanagi
VOLUME /etc/nginx/conf.d
VOLUME /etc/httpd/conf.d
VOLUME /etc/kusanagi.d

COPY files/docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
