#!/bin/bash

mysql_ver="${mysql_ver:-5.5}"
mysql_pw="${mysql_pw:-}"
mysql_size="${mysql_size:-}" # small, medium, large, etc.

mysql_id="${mysql_id:-1}"
mysql_conf=
mysql_svc=

deploy_mysql_rhel() {
  mysql_svc=mysqld
  mysql_conf=/etc/my.cnf

  # Install server
  yum install mysql-server -y

  # Configure
  if [ -n "$mysql_size" ]; then
    cp "/usr/share/mysql/my-$mysql_size.cnf" $mysql_conf
  fi

  # Set runlevels
  chkconfig --levels 345 $mysql_svc on

  # start
  service $mysql_svc start

  if [ -n "$mysql_pw" ]; then
    mysql -u root <<SQL
      UPDATE mysql.user SET Password=PASSWORD('$mysql_pw') WHERE User='root';
      FLUSH PRIVILEGES;
SQL
  fi
}

deploy_mysql_ubuntu() {
  mysql_svc=mysql
  mysql_conf=/etc/mysql/my.cnf

  # Install server
  if [ -n "$mysql_pw" ]; then
    echo "mysql-server-$mysql_ver mysql-server/root_password password $mysql_pw" | debconf-set-selections
    echo "mysql-server-$mysql_ver mysql-server/root_password_again password $mysql_pw" | debconf-set-selections
  fi
  apt-get install mysql-server-$mysql_ver mysql-server -y

  # Configure
  if [ -n "$mysql_size" ]; then
    if [ -e "/usr/share/doc/mysql-server-$mysql_ver/examples/$mysql_size.cnf" ]; then
      cp "/usr/share/doc/mysql-server-$mysql_ver/examples/$mysql_size.cnf" $mysql_conf
    elif [ -e "/usr/share/doc/mysql-server-$mysql_ver/examples/$mysql_size.cnf.gz" ]; then
      gunzip < "/usr/share/doc/mysql-server-$mysql_ver/examples/$mysql_size.cnf.gz" > $mysql_conf
    fi
  fi

  # start
  service $mysql_svc start
}

config_mysql() {
  # Secure mysql
  mysql -u root ${mysql_pw:+--password="${mysql_pw}"} <<SQL
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
    FLUSH PRIVILEGES;
SQL

  # Set id (used for replication)
  perl -pi -e "s/^server-id.*/server-id = $mysql_id/" $mysql_conf

  # restart
  service $mysql_svc restart
}

deploy mysql
config_mysql
