# Start with official php:5-apache image
FROM php:5-apache

# Add a group and user
RUN groupadd --gid 1000 dcutil && \
    useradd --uid 1000 -ms /bin/bash dcutil -g dcutil

# GD and mcrypt
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        libvpx-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
        --with-xpm-dir=/usr/include/ \
        --with-vpx-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && rm -rf /var/lib/apt/lists/*

# Memcached
RUN apt-get update && apt-get install -y libmemcached-dev zlib1g-dev \
    && pecl install memcached-2.2.0 \
    && docker-php-ext-enable memcached \
    && rm -rf /var/lib/apt/lists/*

# Install necessary extensions
RUN docker-php-ext-install pdo_mysql mysqli opcache exif zip gettext

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add vendor bin to PATH
ENV PATH="${HOME}/.composer/vendor/bin:vendor/bin:${PATH}"

# add packages
RUN apt-get update && apt-get install -y bash-completion git nano curl man

# Create the SSL directory
RUN mkdir -p /usr/local/apache2/ssl

# Set /var/www as working directory
WORKDIR /var/www

# turn on needed modules
RUN a2enmod rewrite vhost_alias ssl headers expires socache_shmcb && \
    service apache2 restart

# Give ownership to www-data
RUN chown -R www-data:www-data /var/www