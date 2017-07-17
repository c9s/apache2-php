FROM ubuntu:16.04
# FROM debian:jessie-backports

ENV DEBIAN_FRONTEND="noninteractive"

VOLUME ["/var/www"]

# Use faster apt-get mirror for Taiwan
# RUN perl -i.bak -pe "s/archive.ubuntu.com/free.nchc.org.tw/g" /etc/apt/sources.list
# RUN perl -i.bak -pe "s/archive.ubuntu.com/tw.archive.ubuntu.com/g" /etc/apt/sources.list

# RUN echo "Asia/Taipei" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN echo "Asia/Taipei" > /etc/timezone

# Remove build-in sh with bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh



RUN apt-get update && \
    apt-get install -y php libapache2-mod-php  \
        php-dev php-fpm php-cli php-mysqlnd php-pgsql php-sqlite3 php-redis \
        php-apcu php-intl php-imagick php-mcrypt php-json php-gd php-curl \
        libfreetype6 libfreetype6-dev libpng12-0 libpng12-dev libjpeg-dev libjpeg8-dev libjpeg8  libgd-dev libgd3 libxpm4 libltdl7 libltdl-dev \
        libssl-dev openssl \
        gettext libgettextpo-dev libgettextpo0 \
        libicu-dev \
        libmhash-dev libmhash2 \
        libmcrypt-dev libmcrypt4 \
        ca-certificates \
        libyaml-dev libcurl4-gnutls-dev libexpat1-dev libz-dev \
        libmysqlclient-dev libmysqld-dev curl git wget nginx \
        libpcre3 libpcre3-dev \
    && phpenmod mcrypt \
    && apt-get clean -y \
    && apt-get autoclean -y \
    && apt-get autoremove -y

RUN curl -L -O https://pecl.php.net/get/yaml-2.0.0.tgz && tar xf yaml-2.0.0.tgz && rm yaml-2.0.0.tgz 
RUN echo "extension=yaml.so" > /etc/php/7.0/mods-available/yaml.ini

RUN (cd yaml-2.0.0 && phpize && ./configure --quiet && make clean && make && make install > /dev/null)

ADD etc/php/yaml.ini /etc/php/7.0/mods-available/yaml.ini

RUN a2enmod rewrite
RUN phpenmod yaml && php -v


# patch time zone
RUN sed -i '/date.timezone = /c\date.timezone = Asia/Taipei' $(find /etc/php/7.0 -name php.ini)


# Install composer
# ================
# ADD Dockerfile
# https://stackoverflow.com/questions/31782220/how-can-i-prevent-a-dockerfile-instruction-from-being-cached
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer \
  && chmod +x /usr/local/bin/composer


# override the original apache default config
COPY etc/apache2/default.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www

COPY httpd-foreground /usr/local/bin/

EXPOSE 80 443

CMD ["httpd-foreground"]
