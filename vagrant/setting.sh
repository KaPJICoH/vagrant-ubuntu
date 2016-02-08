#! /usr/bin/env bash

DBNAME=wordpress
DBUSER=root
DBPASSWD=root

echo -e "\n--- Updating---\n"
sudo apt-get -qq update > /dev/null 2>&1

echo -e "\n--- Install base packages (curl, python, git) ---\n"
sudo apt-get -y install curl python-software-properties git > /dev/null 2>&1 

echo -e "\n--- Updating ---\n"
sudo apt-get -qq update > /dev/null 2>&1

echo -e "\n--- Install MySQL(root/root) ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
sudo apt-get -y install mysql-server-5.5 phpmyadmin > /dev/null 2>&1

echo -e "\n--- Create DB(wordpress) ---\n"
mysql -u$DBUSER -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -u$DBUSER -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"

echo -e "\n--- Installing PHP packages ---\n"
sudo apt-get -y install php5 apache2 php5-curl php5-mysql > /dev/null 2>&1

echo -e "\n--- Enabling mod-rewrite ---\n"
a2enmod rewrite > /dev/null 2>&1

echo -e "\n--- Allowingoverride to all ---\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

sudo touch wordpress.dev.conf
cat>/etc/apache2/sites-available/wordpress.dev.conf <<EOF
<VirtualHost *:80>
	ServerName wordpress.dev
	ServerAlias www.wordpress.dev
    DocumentRoot /var/www/wordpress.dev
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined    
</VirtualHost>
EOF

sudo a2ensite wordpress.dev.conf

echo -e "\n--- Configure phpmyadmin ---\n"
echo -e "\n\nListen 81\n" >> /etc/apache2/ports.conf
cat > /etc/apache2/conf-available/phpmyadmin.conf << "EOF"
<VirtualHost *:81>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/share/phpmyadmin
    DirectoryIndex index.php
    ErrorLog ${APACHE_LOG_DIR}/phpmyadmin-error.log
    CustomLog ${APACHE_LOG_DIR}/phpmyadmin-access.log combined
</VirtualHost>
EOF
a2enconf phpmyadmin > /dev/null 2>&1

echo -e "\n--- Add environment variables to Apache ---\n"
cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/wordpress
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined    
</VirtualHost>
EOF

echo -e "\n--- Restarting Apache ---\n"
service apache2 restart > /dev/null 2>&1

echo -e "\n--- Installing Composer for PHP package management ---\n"
curl --silent https://getcomposer.org/installer | php > /dev/null 2>&1
mv composer.phar /usr/local/bin/composer 

cd /var/www
sudo git clone https://github.com/KaPJICoH/wordpress > /dev/null 2>&1
echo -e "\n--- Install wp-cli ---\n"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > /dev/null 2>&1
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
sudo mkdir wordpress.dev

cd wordpress
echo -e "\n--- Import DB ---\n"
mysql -u$DBUSER -p$DBPASSWD $DBNAME < dump.sql
echo -e "\n--- Install WordPress---\n"
sudo composer install > /dev/null 2>&1









