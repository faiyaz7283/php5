# Start with php:5.6-alpine base alpine image
FROM php:5.6-alpine

LABEL maintainer="faiyaz7283@gmail.com"

# Install bash and other helpful tools
RUN apk add --no-cache bash bash-completion busybox-suid sudo git nano curl man

# Add a group and user
RUN addgroup -g 1000 -S dcutil && \
    adduser -D -u 1000 -s /bin/bash -G dcutil dcutil

# Dependencies for php GD
ENV GD_DEPS freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev zlib-dev libxpm-dev \
            libvpx-dev libjpeg-turbo-utils
RUN apk add --no-cache --virtual .gd-deps $GD_DEPS \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
        --with-xpm-dir=/usr/include/ \
        --with-vpx-dir=/usr/include/ \
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && docker-php-ext-install -j${NPROC} gd \
    && rm -rf /tmp/*

# Install memchached extension
ENV MEMCACHED_DEPS zlib-dev libmemcached-dev cyrus-sasl-dev
RUN docker-php-source extract \
    && apk add --no-cache libmemcached-libs libmemcached zlib \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache --virtual .memcached-deps $MEMCACHED_DEPS \
    && pecl install memcached-2.2.0 \
    && docker-php-ext-enable memcached \
    && rm -rf /tmp/* \
    && apk del .memcached-deps .phpize-deps \
    && docker-php-source delete

 # Install apcu extension
RUN docker-php-source extract \
     && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
     && pecl install apcu-4.0.11 \
     && docker-php-ext-enable apcu \
     && rm -rf /tmp/* \
     && apk del .phpize-deps \
     && docker-php-source delete

# Install gettext
RUN docker-php-source extract \
    && apk add --no-cache gettext-dev \
    && docker-php-ext-install gettext \
    && rm -rf /tmp/* \
    && docker-php-source delete

# Install necessary extensions
RUN docker-php-ext-install pdo_mysql mysqli opcache exif zip

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add vendor bin to user's PATH
USER dcutil
RUN echo "" >> "${HOME}/.bashrc" && \
    echo 'export PATH="${HOME}/.composer/vendor/bin:vendor/bin:${PATH}"' >> ~/.bashrc

# Set /var/www as working directory
WORKDIR /var/www