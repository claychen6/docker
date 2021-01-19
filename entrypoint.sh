#!/bin/sh

set -e
nginx && redis-server /etc/redis.conf && /usr/local/sbin/php-fpm --daemonize -R
