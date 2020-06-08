FROM debian:buster

LABEL maintainer="Luca Robino <lrobino@student.42.fr>"

ARG WEB_ROOT="/var/www/html"
ARG AUTO_INDEX="on"

ARG PHP_VERSION="7.3"
ENV PHP_VERSION=${PHP_VERSION}
ARG PHPMYADMIN_VERSION="4.9.4"
ARG MYSQL_PASSWORD="a3k5Kds0dskdsq0D23"

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

# MYSQL INSTALL
RUN apt-get -y install mariadb-server mariadb-client

# WORDPRESS INSTALL
RUN wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -zxf /tmp/wordpress.tar.gz \
    && rm -rf /tmp/wordpress.tar.gz \
    && mv wordpress/* ${WEB_ROOT} \
    && rm -rf wordpress

# NGINX COPY CONFIG
COPY srcs/nginx-default.conf /etc/nginx/sites-enabled/default

# NGINX CONFIG
RUN sed -i "s/autoindex off/autoindex ${AUTO_INDEX}/" /etc/nginx/sites-enabled/default \
# Using '+' as delimiter in sed because strings contains '/'
    && sed -i "s+root /var/www/html+root ${WEB_ROOT}+" /etc/nginx/sites-enabled/default


# EXPOSED PORTS
EXPOSE 80 443


CMD service php${PHP_VERSION}-fpm start \
    && nginx -g "daemon off;"
