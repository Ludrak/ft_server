FROM debian:buster

LABEL maintainer="Luca Robino <lrobino@student.42Lyon.fr>"

# SERVER
ARG NAME="127.0.0.1"
ARG WEB_ROOT="/var/www/html"
ARG AUTO_INDEX="off"

# WORDPRESS
ARG WP_DB="wordpress"
ARG WP_USER="wordpress-usr"
ARG WP_PASS="23hjDF67dsSQ86e2"

# PHP
ENV PHP_VERSION="7.3"
ARG PHP_USER="php-usr"
ARG PHP_PASS="mFjY2VwdGFibGUgZ"

# PHPMYADMIN
ARG PHPMYADMIN_VERSION="5.0.2"
ARG PMA_DB="phpmyadmin"
ARG PHPMYADMIN_SECRET="Z2hmhgfmaGZzaGfds2ZzZgfdgmZHNnc2ZkZutrZGdN6erf2ZnaGZoc2ZoZnNoZm"

ENV DEBIAN_FRONTEND=noninteractive



# DEPENDECIES
RUN apt-get update && apt-get upgrade && apt-get install -y wget ssl-cert lsb-release gnupg unzip

# WEB ROOT CONFIG
RUN mkdir -p ${WEB_ROOT} && \
    chown -R www-data:www-data ${WEB_ROOT} && \
    chmod -R 775 ${WEB_ROOT}



##              INSTALL
##           -------------

# NGINX & PHP INSTALL
RUN apt-get update && apt-get install -y nginx
RUN apt-get update && apt-get install -y php${PHP_VERSION} \
                    php${PHP_VERSION}-fpm \
                    php${PHP_VERSION}-cli \
                    php${PHP_VERSION}-common \
                    php${PHP_VERSION}-mbstring \
                    php${PHP_VERSION}-mysql \
                    php${PHP_VERSION}-gd \
                    php${PHP_VERSION}-curl \
                    php${PHP_VERSION}-imagick \
                    php${PHP_VERSION}-zip \
                    php${PHP_VERSION}-dom

# PHPMYADMIN INSTALL
RUN wget -qO /tmp/phpmyadmin.zip https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.zip \
    && unzip /tmp/phpmyadmin.zip \
    && rm -rf /tmp/phpmyadmin.zip \
    && mv phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages /usr/share/phpmyadmin \
    && chown -R www-data:www-data /usr/share/phpmyadmin \
    && chmod -R 775 /usr/share/phpmyadmin \
    && ln -s /usr/share/phpmyadmin ${WEB_ROOT}

# MARIADB INSTALL
RUN apt-get update && apt-get -y install mariadb-server

# WORDPRESS INSTALL
RUN wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -zxf /tmp/wordpress.tar.gz \
    && rm -rf /tmp/wordpress.tar.gz \
    && mv wordpress/ ${WEB_ROOT}/wordpress \
    && chown -R www-data:www-data ${WEB_ROOT}/wordpress \
    && rm -rf wordpress



##              CONFIG
##           ------------

# PHP CONFIG
RUN cd /usr/share/phpmyadmin \
    && sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '${PHPMYADMIN_SECRET}'|" config.sample.inc.php > config.inc.php

# WORDPRESS CONFIG
RUN cd ${WEB_ROOT}/wordpress \
    && sed -e "s/database_name_here/${WP_DB}/" \
            -e "s/username_here/${WP_USER}/" \
            -e "s/password_here/${WP_PASS}/" \
            -e "s+\/\* That's all, stop editing! Happy publishing. \*\/+define\( \"FS_METHOD\", \"direct\" \);+" \
        wp-config-sample.php > wp-config.php

# MYSQL CONFIG
RUN /etc/init.d/mysql start \
    #phpmyadmin database w/ php user
    && mysql -e "CREATE DATABASE ${PMA_DB} ; \
                CREATE USER '${PHP_USER}' IDENTIFIED BY '${PHP_PASS}' ; \
                GRANT ALL PRIVILEGES ON ${PMA_DB}.* TO '${PHP_USER}' ; \
                FLUSH PRIVILEGES ; \
    #wp database w/ wp user
                CREATE DATABASE ${WP_DB} ; \
                CREATE USER '${WP_USER}' IDENTIFIED BY '${WP_PASS}' ; \
                GRANT ALL PRIVILEGES ON ${WP_DB}.* TO '${WP_USER}' ; \
                FLUSH PRIVILEGES ; \
                "

# NGINX COPY CONFIG
COPY srcs/nginx-default.conf /etc/nginx/sites-enabled/default

# NGINX CONFIG
RUN cd /etc/nginx/sites-enabled/ \
    && sed -i "s/autoindex off/autoindex ${AUTO_INDEX}/" default \
    && sed -i "s+root /var/www/html+root ${WEB_ROOT}+" default \
    && sed -i "s/php7.3-fpm/php${PHP_VERSION}-fpm/" default \
    && sed -i "s/server_name_here/${NAME}/" default \
    && if [ "${AUTO_INDEX}" = "on" ] ; then \
            sed -i "s/index index.php;/#/" default ; \
            sed -i "s+location = / { return 301 /wordpress; }+#+" default ; \
        fi



# EXPOSED PORTS
EXPOSE 80 443

CMD /etc/init.d/mysql start \
    && service php${PHP_VERSION}-fpm start \
    && nginx -g "daemon off;"
