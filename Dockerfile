FROM php:7.2-fpm-alpine3.12

# Environment
ENV TIMEZONE            Asia/Shanghai
ENV PHP_MEMORY_LIMIT    512M
ENV MAX_UPLOAD          50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST        100M
ENV COMPOSER_ALLOW_SUPERUSER 1

COPY ./php/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./entrypoint.sh /home/entrypoint.sh
COPY ./nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

VOLUME [ "/home/www", "/home/log" ]

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
  && apk update && apk upgrade \
  && apk add vim screen curl wget tzdata git composer nginx supervisor redis \
  && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
  && apk del tzdata \
  && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
  && set -x \
	&& addgroup -g 1000 -S www \
	&& adduser -u 2001 -D -S -G www www \
  && chown www:www -R /home && chmod -R 755 /home \
  && chmod +x /home/entrypoint.sh

RUN apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
  && docker-php-ext-install pdo_mysql \
  && pecl install -o redis \
  && docker-php-ext-enable redis \
  && rm -rf /var/cache/apk/* \
  && rm -rf /usr/share/php \
  && rm -rf /tmp/* \
  && apk del .phpize-deps

# Set environments
RUN sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini && \
	sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
	sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php7/php.ini && \
	sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
	sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
	sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php7/php.ini

EXPOSE 80
WORKDIR /home/www

ENTRYPOINT ["/home/entrypoint.sh"]
