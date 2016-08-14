# Dockerfile for Phabricator
# Phillip Hansen, March 2016

FROM ubuntu:14.04
MAINTAINER Phillip Hansen <phil@sg20.com>
EXPOSE 22 80

# Install required packages
# For Nginx, need curl installed first in order to download the repo signing key
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        mercurial \
        mysql-client-5.6 \
        openssh-server \
        php5 \
        php5-cli \
        php5-curl \
        php5-dev \
        php5-fpm \
        php5-gd \
        php5-json \
        php5-mysql \
        php-apc \
        postfix \
        python-pygments && \
    cd /tmp && \
    curl -O http://nginx.org/keys/nginx_signing.key && \
    apt-key add nginx_signing.key && \
    echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list && \
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Nginx config
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/phabricator.conf /etc/nginx/conf.d/default.conf

# Set up fpm config
RUN sed -i.bak 's/www-data/nginx/g; \
        s/pm.max_children.*$/pm.max_children = 100/; \
        s/pm.start_servers.*$/pm.start_servers = 5/; \
        s/pm.min_spare_servers.*$/pm.min_spare_servers = 5/; \
        s/pm.max_spare_servers.*$/pm.max_spare_servers = 20/' /etc/php5/fpm/pool.d/www.conf

# Set up PHP config
RUN sed -i 's/;date.timezone =/date.timezone = "America\/Los_Angeles"/; \
        s/short_open_tag = Off/short_open_tag = On/; \
        s/;opcache.enable=0/opcache.enable=1/; \
        s/;opcache.enable_cli=0/opcache.enable_cli=1/; \
        s/;opcache.memory_consumption=64/opcache.memory_consumption=128/; \
        s/;opcache.validate_timestamps=1/opcache.validate_timestamps=0/; \
        s/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/; \
        s/;opcache.fast_shutdown=0/opcache.fast_shutdown=1/; \
        s/memory_limit =.*$/memory_limit = -1/; \
        s/post_max_size =.*$/post_max_size = 32M/; \
        s/upload_max_filesize =.*$/upload_max_filesize = 2048M/' /etc/php5/fpm/php.ini
        
# MySQL client config
COPY mysql-conf.d /etc/mysql/conf.d

# Set up sshd
COPY sshd/sshd_config /etc/ssh/sshd_config
COPY sshd/phabricator-ssh-hook.sh /etc/ssh/phabricator-ssh-hook.sh
RUN dpkg-reconfigure openssh-server && \
    chmod +x /etc/ssh/phabricator-ssh-hook.sh

# User for phabricator repos
RUN adduser vcsuser && \
    usermod -p '*' vcsuser && \
    echo "vcsuser ALL=(ALL) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/hg" >> /etc/sudoers

# Get Phabricator and its dependencies
RUN cd /opt && \
    git clone https://github.com/phacility/libphutil.git && \
    git clone https://github.com/phacility/arcanist.git && \
    git clone https://github.com/phacility/phabricator.git

# Add start script
COPY start.sh /start.sh
RUN chmod +x /*.sh

CMD ["/start.sh"]
