FROM alpine:3.11

# compile httpd and php, add redis, xdebug, 
# compose to access php & apache logs via volumes

ENV HTTPD_VERSION=2.4.43
ENV PHP_VERSION=7.3.17
ENV PECL_EXTENSIONS="redis xdebug"

# COPY ./src/httpd-$HTTPD_VERSION.tar.bz2 /tmp/
# COPY ./src/php-$PHP_VERSION.tar.bz2 /tmp/

RUN wget --directory-prefix=/tmp/ \
    http://mirror.netinch.com/pub/apache//httpd/httpd-$HTTPD_VERSION.tar.bz2 \
    && \
    wget --directory-prefix=/tmp/ \
    https://www.php.net/distributions/php-$PHP_VERSION.tar.bz2


RUN apk update && apk add \
                apr-dev \
                apr-util-dev \
                pcre-dev \
                build-base \
                gcc \
                abuild \
                cmake \
                extra-cmake-modules \
                libxml2-dev \
                autoconf \
    ; \
    tar -xf /tmp/httpd-$HTTPD_VERSION.tar.bz2 -C /tmp/ \
    ; \
    cd /tmp/httpd-$HTTPD_VERSION/ \
    ; \
    ./configure --enable-so && make && make install \
    ; \
    cd /tmp/ \
    ; \
    tar -xf /tmp/php-$PHP_VERSION.tar.bz2 -C /tmp/ \
    ; \
    cd /tmp/php-$PHP_VERSION/ \
    ; \
    ./configure --with-apxs2=/usr/local/apache2/bin/apxs && make && make install

COPY ./cfg/php.ini /usr/local/lib

RUN cd /tmp/php-$PHP_VERSION/ext/openssl/ \
    ; \
    cp config0.m4 config.m4 && \
    phpize && ./configure && make && make install \
    ; \
    for EXTENSION in $PECL_EXTENSIONS; do yes '' | pecl install $EXTENSION; done \
    ; \
    apk del autoconf extra-cmake-modules cmake abuild gcc build-base; \
    rm -rf /tmp/*

COPY ./cfg/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./cfg/php.conf /usr/local/apache2/conf.d/php.conf
# COPY ./www/* /usr/local/apache2/htdocs/

# RUN chmod +x -R /usr/local/apache2/htdocs/*.php

CMD ["/usr/local/apache2/bin/httpd","-D","FOREGROUND"]
EXPOSE 80