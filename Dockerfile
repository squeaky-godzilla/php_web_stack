FROM alpine:3.11

# compile httpd and php, add redis, xdebug, 
# compose to access php & apache logs via volumes
# TODO:
# - checksums

ARG HTTPD_VERSION=2.4.43
ARG PHP_VERSION=7.3.17

ARG HTTPD_BUILD_DEPS="autoconf extra-cmake-modules cmake abuild gcc build-base bash pcre-dev apr-dev apr-util-dev"

ARG PHP_BUILD_DEPS="autoconf extra-cmake-modules cmake abuild gcc build-base bash pcre-dev libxml2-dev"

RUN wget --directory-prefix=/tmp/ \
    http://mirror.netinch.com/pub/apache//httpd/httpd-$HTTPD_VERSION.tar.bz2
RUN wget --directory-prefix=/tmp/ \
    https://www.php.net/distributions/php-$PHP_VERSION.tar.bz2

# build httpd

RUN apk add --no-cache ${HTTPD_BUILD_DEPS}; \
    tar -xf /tmp/httpd-${HTTPD_VERSION}.tar.bz2 -C /tmp/ \
    ; \
    cd /tmp/httpd-${HTTPD_VERSION}/ || exit \
    ; \
    ./configure --enable-so; make; make install > /tmp/httpd_install_commands.txt;

# build php

RUN apk add --no-cache ${PHP_BUILD_DEPS}; \
    cd /tmp/ || exit \
    ; \
    tar -xf /tmp/php-${PHP_VERSION}.tar.bz2 -C /tmp/ \
    ; \
    cd /tmp/php-${PHP_VERSION}/ || exit \
    ; \
    ./configure --with-apxs2=/usr/local/apache2/bin/apxs --with-openssl; make; make install > /tmp/php_install_commands.txt


# build openssl & instal other php extensions via pecl

ARG PECL_EXTENSIONS="redis xdebug"

RUN for EXTENSION in ${PECL_EXTENSIONS}; do yes '' | pecl install $EXTENSION; done;
RUN apk del ${HTTPD_BUILD_DEPS} ${PHP_BUILD_DEPS}; rm -rf /tmp/*

# copy the binaries to a fresh image with run deps

FROM alpine:3.11

ARG HTTPD_RUN_DEPS="apr apr-util"
ARG PHP_RUN_DEPS="pcre libxml2"

RUN apk add --no-cache ${HTTPD_RUN_DEPS} ${PHP_RUN_DEPS}

COPY --from=0 /usr/local/apache2/ /usr/local/apache2/
COPY --from=0 /usr/local/lib/php/ /usr/local/lib/php/
COPY --from=0 /usr/local/bin/ /usr/local/bin/
COPY --from=0 /usr/local/php/ /usr/local/php/
COPY --from=0 /usr/local/etc/pear.conf /usr/local/etc/pear.conf
COPY --from=0 /usr/local/include/php/ /usr/local/include/php/

CMD ["/usr/local/apache2/bin/httpd","-D","FOREGROUND"]
WORKDIR /usr/local/apache2/htdocs/
EXPOSE 80