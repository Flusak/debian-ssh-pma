#!/bin/bash
if [ $EUID -ne 0 ]
then
echo Error: script running not by sudo
exit
fi

sed -i '/^deb cdrom/s/^deb/#deb/g' /etc/apt/sources.list

read -p "Input proxy (if not Enter): " useproxy
if ! [ -z "$useproxy" ]
then
  if ! cat /etc/apt/apt.conf | grep "Acquire::http::Proxy \"$useproxy\";" >> /dev/null
  then 
  echo "Acquire::http::Proxy \"$useproxy\";" >> /etc/apt/apt.conf
  fi
fi

apt-get -y install apache2 php mariadb-server &&

mysql_secure_installation &&
read -sp "New password for admin in mariadb: " pass_bd &&
echo $'\n' &&
mysql --execute="GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY '$pass_bd' WITH GRANT OPTION;" &&
mysql --execute="ALTER USER 'admin'@'localhost' IDENTIFIED BY '$pass_bd';" &&
read -sp "Control password for pma: " control_pass &&
echo $'\n'
read -sp "Password for blowfish_secret: " blow_sec &&

mkdir -p /var/lib/phpmyadmin/tmp &&
mkdir -p /usr/share/phpmyadmin &&
chown -R www-data:www-data /var/lib/phpmyadmin &&

tar xvf php.tar.gz -C /usr/share/phpmyadmin --strip-components 1 &&

cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php &&
#Раскоментить все у storage database and tables
#Удаление // по шаблону если есть Servers в строке
sed -i '/\$cfg\s*\[.Servers.\]/s/^\/\/\s//g' /usr/share/phpmyadmin/config.inc.php &&
sed -i "/\$cfg\[.blowfish_secret.]\s=\s..;/s/''/'$blow_sec'/" /usr/share/phpmyadmin/config.inc.php &&
sed -i "/\$cfg\[.Servers.\]\[\$i\]\[.controlpass.\]/s/pmapass/$control_pass/g" /usr/share/phpmyadmin/config.inc.php &&
echo "\$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';" >> /usr/share/phpmyadmin/config.inc.php &&
mysql --execute="GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '$control_pass'; FLUSH PRIVILEGES;" &&
mysql < /usr/share/phpmyadmin/sql/create_tables.sql &&

rm -rf /usr/share/phpmyadmin/setup &&
apt-get install -y php-mysql &&
cat apache.txt > /etc/apache2/conf-available/pma.conf &&

apt-get -y install php-mysql &&
a2enconf pma &&
service apache2 restart &&

echo -e '\033[0;32mSuccess!\033[0m' &&

ip_con=$(ip a | egrep "inet[^6]" | egrep -v 127 |tr -s "\t " " "| cut -f3 -d' ' | cut -f1 -d/) &&
port_con=$(sudo ss -tunlp | egrep apa|tr -s "\t " " " | cut -f5 -d' '| cut -d: -f2) &&
echo $ip_con:$port_con/phpmyadmin

echo $'\n'
