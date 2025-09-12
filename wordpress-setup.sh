#!/bin/bash
set -euo pipefail

# =========================================================
#  Automated WordPress Setup Script (Ubuntu 22.04/24.04+)
# =========================================================
# Features:
# - Installs Nginx, PHP, MariaDB, Redis, Fail2Ban, Logwatch
# - Configures SSL with Let's Encrypt
# - Sets up WP-CLI + auto updates + backups
# - Hardens SSH & MySQL
# =========================================================

# -------------------- CONFIG --------------------
WORDPRESS_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"

# -------------------- INPUT ---------------------
read -rp "Enter your domain (e.g., example.com): " domain
read -rp "Enter your email (for Let's Encrypt & WP admin): " email
read -rp "Enter MySQL root password: " mysql_root_password
read -rp "Enter MySQL WordPress user password: " mysql_wp_password
read -rp "Enter WordPress admin username: " wp_admin_user
read -rsp "Enter WordPress admin password: " wp_admin_pass
echo

# -------------------- PREP ----------------------
log_file="/var/log/wordpress-setup-$(date +%F-%T).log"
exec > >(tee -a "$log_file") 2>&1

echo ">>> Updating system..."
apt-get update -y
apt-get upgrade -y

# Ensure a sudo user exists before disabling root SSH login
if ! id "deployer" &>/dev/null; then
    echo ">>> Creating deployer user with sudo access..."
    adduser --disabled-password --gecos "" deployer
    usermod -aG sudo deployer
    mkdir -p /home/deployer/.ssh
    chmod 700 /home/deployer/.ssh
    echo ">>> Please add your SSH key to /home/deployer/.ssh/authorized_keys before locking root!"
fi

# -------------------- PACKAGES ------------------
echo ">>> Installing required packages..."
apt-get install -y software-properties-common curl gnupg2 ca-certificates lsb-release apt-transport-https

# PHP repo (only if needed)
if ! apt-cache policy | grep -q "ondrej/php"; then
    add-apt-repository -y ppa:ondrej/php
fi

# Nginx repo
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx.gpg
codename=$(lsb_release -cs)
echo "deb [signed-by=/usr/share/keyrings/nginx.gpg] http://nginx.org/packages/mainline/ubuntu $codename nginx" > /etc/apt/sources.list.d/nginx.list

apt-get update -y
apt-get install -y nginx mariadb-server php8.2-fpm php8.2-cli php8.2-mysql php8.2-curl php8.2-xml php8.2-mbstring php8.2-zip php8.2-gd php8.2-intl redis-server unzip fail2ban ufw certbot python3-certbot-nginx logwatch rsync

# -------------------- MYSQL ---------------------
echo ">>> Securing MariaDB..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${mysql_root_password}'); FLUSH PRIVILEGES;"

db_name="wordpress_${domain//./_}"
mysql -uroot -p"$mysql_root_password" -e "CREATE DATABASE IF NOT EXISTS ${db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p"$mysql_root_password" -e "CREATE USER IF NOT EXISTS 'wp_user'@'localhost' IDENTIFIED BY '${mysql_wp_password}';"
mysql -uroot -p"$mysql_root_password" -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO 'wp_user'@'localhost'; FLUSH PRIVILEGES;"

# -------------------- REDIS ---------------------
echo ">>> Configuring Redis..."
redis_pass=$(openssl rand -base64 32)
sed -i "s/^# requirepass .*/requirepass $redis_pass/" /etc/redis/redis.conf
systemctl restart redis-server

# -------------------- WORDPRESS -----------------
echo ">>> Downloading WordPress..."
mkdir -p /var/www/$domain
curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
tar -xzf /tmp/wordpress.tar.gz -C /tmp
rsync -av /tmp/wordpress/ /var/www/$domain/
chown -R www-data:www-data /var/www/$domain
chmod -R 755 /var/www/$domain

# -------------------- NGINX ---------------------
echo ">>> Configuring Nginx..."
cat >/etc/nginx/sites-available/$domain <<EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain;

    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)\$ {
        expires max;
        log_not_found off;
    }

    client_max_body_size 64M;
    limit_req zone=one burst=10 nodelay;

    location = /xmlrpc.php {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# -------------------- SSL -----------------------
echo ">>> Obtaining SSL certificate..."
certbot --nginx -d $domain -d www.$domain --non-interactive --agree-tos -m $email || echo "Certbot failed, retry manually later."

# -------------------- WP-CLI --------------------
echo ">>> Installing WP-CLI..."
curl -o /usr/local/bin/wp $WORDPRESS_CLI_URL
chmod +x /usr/local/bin/wp

# -------------------- WORDPRESS CONFIG ----------
echo ">>> Configuring WordPress..."
cd /var/www/$domain
wp config create --dbname=$db_name --dbuser=wp_user --dbpass=$mysql_wp_password --dbhost=localhost --allow-root
wp core install --url="https://$domain" --title="WordPress Site" --admin_user=$wp_admin_user --admin_password=$wp_admin_pass --admin_email=$email --allow-root

# Enable Redis cache
wp config set WP_REDIS_PASSWORD "$redis_pass" --allow-root
wp config set WP_CACHE true --allow-root
wp plugin install redis-cache --activate --allow-root
wp redis enable --allow-root

chown -R www-data:www-data /var/www/$domain

# -------------------- FIREWALL ------------------
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# -------------------- FAIL2BAN ------------------
systemctl enable fail2ban
systemctl start fail2ban

# -------------------- CRON JOBS -----------------
echo ">>> Setting up cron jobs..."
cat >/etc/cron.daily/wordpress-update <<'EOF'
#!/bin/bash
for site_dir in /var/www/*/; do
    if [[ -f "$site_dir/wp-config.php" ]]; then
        wp core update --allow-root --path="$site_dir"
        wp plugin update --all --allow-root --path="$site_dir"
    fi
done
EOF
chmod +x /etc/cron.daily/wordpress-update

cat >/usr/local/bin/wordpress-backup <<EOF
#!/bin/bash
backup_dir="/var/backups/wordpress/\$(date +%F)"
mkdir -p \$backup_dir
for site_dir in /var/www/*/; do
    if [[ -f "\$site_dir/wp-config.php" ]]; then
        sitename=\$(basename \$site_dir)
        wp db export --allow-root --path="\$site_dir" "\$backup_dir/\$sitename.sql"
        rsync -a \$site_dir "\$backup_dir/\$sitename-files"
    fi
done
EOF
chmod +x /usr/local/bin/wordpress-backup

echo "0 3 * * * root /usr/local/bin/wordpress-backup" >/etc/cron.d/wordpress-backup

# -------------------- LOGWATCH ------------------
echo "MailTo = $email" >> /etc/logwatch/conf/logwatch.conf

# -------------------- SSH HARDENING -------------
echo ">>> Hardening SSH..."
sed -i 's/#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd || true

# -------------------- DONE ----------------------
echo "================================================="
echo " WordPress installation completed!"
echo " Domain: https://$domain"
echo " DB Name: $db_name"
echo " DB User: wp_user"
echo " DB Pass: $mysql_wp_password"
echo " Redis Pass: $redis_pass"
echo " Log file: $log_file"
echo "================================================="

