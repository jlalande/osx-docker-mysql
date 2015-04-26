#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

# Tweaks to give Apache/PHP write permissions to the app
chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld
chmod -R 770 /var/lib/mysql
chmod -R 770 /var/run/mysqld

if [ -n "$VAGRANT_OSX_MODE" ];then
    usermod -u $DOCKER_USER_ID mysql
    groupmod -g $(($DOCKER_USER_GID + 10000)) $(getent group $DOCKER_USER_GID | cut -d: -f1)
    groupmod -g ${DOCKER_USER_GID} staff
    chmod -R 770 /var/lib/mysql
    chmod -R 770 /var/run/mysqld
    chown -R mysql:mysql /var/lib/mysql
    chown -R mysql:mysql /var/run/mysqld
else
    # Tweaks to give Apache/PHP write permissions to the app
    chmod -R 770 /var/lib/mysql
    chmod -R 770 /var/run/mysqld
    chown -R mysql:mysql /var/lib/mysql
    chown -R mysql:mysql /var/run/mysqld
fi

sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/my.cnf
sed -i "s/user.*/user = mysql/" /etc/my.cnf
# Move mysql.sock to a different place than the mysql volume to avoid permission issues
sed -i "s/socket.*/socket = \/var\/lib\/mysql_sock\/mysql.sock/" /etc/my.cnf

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db > /dev/null 2>&1
    echo "=> Done!"
    /create_mysql_users.sh
else
    echo "=> Using an existing volume of MySQL"
fi

exec supervisord -n -c /etc/supervisord.conf
