# syntax=docker/dockerfile:1

FROM composer:lts as prod-deps
WORKDIR /app
RUN --mount=type=bind,source=./docker-php-sample/composer.json,target=composer.json \
    --mount=type=bind,source=./docker-php-sample/composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-dev --no-interaction

FROM composer:lts as dev-deps
WORKDIR /app
RUN --mount=type=bind,source=./docker-php-sample/composer.json,target=composer.json \
    --mount=type=bind,source=./docker-php-sample/composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-interaction

FROM php:8.3.3-apache as base
RUN docker-php-ext-install pdo pdo_mysql
COPY ./docker-php-sample/src /var/www/html

FROM base as development
COPY ./docker-php-sample/tests /var/www/html/tests
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY --from=dev-deps app/vendor/ /var/www/html/vendor

FROM development as test
WORKDIR /var/www/html
RUN ./vendor/bin/phpunit tests/HelloWorldTest.php

FROM base as final
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY --from=prod-deps app/vendor/ /var/www/html/vendor
USER www-data