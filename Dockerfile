FROM debian:buster

LABEL maintainer="Luca Robino <lrobino@student.42.fr>"

ARG WEB_ROOT="/var/www/html"
ARG AUTO_INDEX="on"

ARG MYSQL_USR="mysql"
ARG MYSQL_BASEDIR="/opt/mysql/mysql"
ARG MYSQL_DATADIR="/opt/mysql/mysql/data"

ARG WP_DB="wordpress"
ARG WP_USER="wordpress"
ARG WP_PASS="23hjDF67dsSQ86e2"

ARG PHP_VERSION="7.3"
ENV PHP_VERSION=${PHP_VERSION}
ARG PHPMYADMIN_VERSION="4.9.4"

ARG PHP_USER="php"
ARG PHP_PASS="mFjY2VwdGFibGUgZ"

ENV DEBIAN_FRONTEND=noninteractive

# DEPENDECIES
RUN apt-get update && apt-get install -y apt-utils wget ssl-cert curl lsb-release gnupg unzip

# WEB ROOT CONFIG
RUN mkdir -p ${WEB_ROOT} && \
    chown -R www-data:www-data ${WEB_ROOT} && \
    chmod -R 775 ${WEB_ROOT}

# NGINX & PHP INSTALL
RUN apt-get install -y nginx
RUN apt-get install -y php${PHP_VERSION} \
                    php${PHP_VERSION}-fpm \
                    php${PHP_VERSION}-common \
                    php${PHP_VERSION}-cli \
                    php${PHP_VERSION}-mbstring \
                    php${PHP_VERSION}-mysql
RUN wget -qO /tmp/phpmyadmin.zip https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.zip \
    && unzip /tmp/phpmyadmin.zip \
    && rm -rf /tmp/phpmyadmin.zip \
    && mv phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages /usr/share/phpmyadmin \
    && chown -R www-data:www-data /usr/share/phpmyadmin \
    && chmod -R 775 /usr/share/phpmyadmin \
    && ln -s /usr/share/phpmyadmin ${WEB_ROOT}

# MARIADB INSTALL
RUN apt-get -y install mariadb-server mariadb-client

# WORDPRESS INSTALL
RUN wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -zxf /tmp/wordpress.tar.gz \
    && rm -rf /tmp/wordpress.tar.gz \
    && mv wordpress/* ${WEB_ROOT} \
    && rm -rf wordpress

# MYSQL CONFIG
RUN /etc/init.d/mysql start \
    && mysql -e "CREATE DATABASE phpmyadmin ; \
                CREATE USER ${PHP_USER} IDENTIFIED BY '${PHP_PASS}' ; \
                GRANT ALL PRIVILEGES ON phpmyadmin.* TO ${PHP_USER} IDENTIFIED BY '${PHP_PASS}'; \
                CREATE DATABASE ${WP_DB} ; \
                CREATE USER ${WP_USER} IDENTIFIED BY '${WP_PASS}' ; \
                GRANT ALL PRIVILEGES ON ${WP_DB}.* TO ${WP_USER} IDENTIFIED BY '${WP_PASS}' ; \
                " \
    && /etc/init.d/mysql stop

# WORDPRESS CONFIG
RUN cd ${WEB_ROOT} \
    && sed -e "s/database_name_here/${WP_DB}/" -e "s/username_here/${WP_USER}/" -e "s/password_here/${WP_PASS}/" wp-config-sample.php > wp-config.php

# NGINX COPY CONFIG
COPY srcs/nginx-default.conf /etc/nginx/sites-enabled/default

# NGINX CONFIG
RUN sed -i "s/autoindex off/autoindex ${AUTO_INDEX}/" /etc/nginx/sites-enabled/default \
# Using '+' as delimiter in sed because strings contains '/'
    && sed -i "s+root /var/www/html+root ${WEB_ROOT}+" /etc/nginx/sites-enabled/default

# EXPOSED PORTS
EXPOSE 80 443

CMD /etc/init.d/mysql start \
    && service php${PHP_VERSION}-fpm start \
    && nginx -g "daemon off;"
