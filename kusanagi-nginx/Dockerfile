#//----------------------------------------------------------------------------
#// CentOS 7 ベース
#//----------------------------------------------------------------------------
FROM centos:7
MAINTAINER d-higuchi@creationline.com

#//----------------------------------------------------------------------------
#// Kusanagi パッケージバージョン
#//----------------------------------------------------------------------------
ENV KUSANAGI_VERSION		7.8.2-2
ENV KUSANAGI_WP_VERSION		4.5.2-1
ENV KUSANAGI_NGINX_VERSION	1.10.0-1
ENV KUSANAGI_LIBBROTLI_VERSION	1.0pre1-2
ENV KUSANAGI_OPENSSL_VERSION	1.0.2h-1

#//----------------------------------------------------------------------------
#// グループとユーザの作成
#//----------------------------------------------------------------------------
RUN groupadd -g 1000 www \
	&& groupadd -g 1001 kusanagi \
	&& useradd -d /home/httpd -c '' -s /bin/false -G www -M -u 1000 httpd \
	&& useradd -d /home/kusanagi -c '' -s /bin/bash -g kusanagi -G www -u 1001 kusanagi \
	&& chmod 755 /home/kusanagi

#//----------------------------------------------------------------------------
#// Kusanagi パッケージの取得とインストール、後始末
#//
#// NOTE:
#//
#// kusanagi.rpm は Requires: kusanagi-{hhvm,nginx,php7,wp,wp-cli}
#// kusanagi-openssl.rpm は Requires: perl なので nodeps でインストール。
#//----------------------------------------------------------------------------
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

#//----------------------------------------------------------------------------
#// 必要なディレクトリの作成と、エラーを起こす処理のコメントアウト
#//----------------------------------------------------------------------------
RUN mkdir -p /var/log/nginx /etc/nginx/conf.d /etc/httpd/conf.d \
	&& sed -i 's/^sed.*\/etc\/hosts/#sed/' /usr/lib/kusanagi/lib/virt.sh \
	&& sed -i 's/systemctl/\/bin\/true/g' /usr/lib/kusanagi/lib/virt.sh

#//----------------------------------------------------------------------------
#// 永続データのディレクトリ指定
#//----------------------------------------------------------------------------
VOLUME /home/kusanagi
VOLUME /etc/nginx/conf.d
VOLUME /etc/httpd/conf.d

#//----------------------------------------------------------------------------
#// 自己証明書の作成と /usr/lib/kusanagi/lib/virt.sh の実行
#//----------------------------------------------------------------------------
COPY files/docker-entrypoint.sh /

#//----------------------------------------------------------------------------
#// 起動
#//----------------------------------------------------------------------------
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]

#//----------------------------------------------------------------------------
#// [EOF]
#//----------------------------------------------------------------------------
