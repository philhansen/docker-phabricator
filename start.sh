#!/bin/bash

export PATH="/opt/phabricator/bin:$PATH"

# set permissions on storage folders
chmod a+rw /var/repo
chmod a+rw /var/storage

# Apply any pending DB schema upgrades
/opt/phabricator/bin/storage upgrade --force

service rsyslog start
service postfix start
service ssh start

# start phabricator daemons
/opt/phabricator/bin/phd start
/etc/init.d/php5-fpm start
# start nginx in foreground
nginx -g "daemon off;"
