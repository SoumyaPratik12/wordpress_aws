#!/bin/bash
set -e
yum update -y
yum install -y httpd mysql php php-mysqlnd php-fpm php-json wget

systemctl enable httpd
systemctl start httpd

# Install MariaDB
yum install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb

# Set up WordPress DB
WP_DB_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
mysql -u root -e "CREATE DATABASE wordpress;"
mysql -u root -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY '$WP_DB_PASS';"
mysql -u root -e "GRANT ALL ON wordpress.* TO 'wpuser'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Download and configure WordPress
cd /var/www/html
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/wordpress/" wp-config.php
sed -i "s/username_here/wpuser/" wp-config.php
sed -i "s/password_here/$WP_DB_PASS/" wp-config.php
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Save passwords to SSM Parameter Store
WP_ADMIN_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
aws ssm put-parameter --name "/wp-platform/demo-site/db-password"       --value "$WP_DB_PASS"    --type SecureString --region $REGION --overwrite || true
aws ssm put-parameter --name "/wp-platform/demo-site/wp-admin-password" --value "$WP_ADMIN_PASS" --type SecureString --region $REGION --overwrite || true

# Configure Apache for WordPress
cat > /etc/httpd/conf.d/wordpress.conf <<'APACHECONF'
<Directory /var/www/html>
  AllowOverride All
  Require all granted
</Directory>
APACHECONF

# Write .htaccess
cat > /var/www/html/.htaccess <<'HTACCESS'
# BEGIN WordPress
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
HTACCESS

# Enable mod_rewrite
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf

systemctl restart httpd
echo "WordPress setup complete" > /var/log/wp-setup.log
