#!/bin/bash

# Modern WordPress Setup Script for 2025
# Optimized for Ubuntu 22.04/24.04 LTS, PHP 8.3, Nginx, Redis
# Security & Performance Focused

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="2.0.0"
LOG_FILE="/var/log/wordpress-setup-$(date +%Y%m%d-%H%M%S).log"
PHP_VERSION="8.3"
NGINX_VERSION="mainline"  # Use mainline for latest features
WORDPRESS_CLI_VERSION="latest"

# Logging setup
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Modern WordPress Setup Script v${SCRIPT_VERSION}${NC}"
echo -e "${BLUE}Started: $(date)${NC}"
echo -e "${BLUE}============================================${NC}"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

error_exit() {
    log_error "$1"
    log_error "Setup failed at $(date). Check $LOG_FILE for details."
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root (use sudo)"
    fi
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error_exit "Cannot determine OS version"
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        error_exit "This script only supports Ubuntu. Detected: $ID"
    fi
    
    case "$VERSION_ID" in
        "22.04"|"24.04")
            log_info "Detected Ubuntu $VERSION_ID LTS - Supported"
            ;;
        *)
            log_warn "Ubuntu $VERSION_ID may not be fully supported. Recommended: 22.04 or 24.04 LTS"
            read -p "Continue anyway? (y/N): " continue_anyway
            [[ "$continue_anyway" =~ ^[Yy]$ ]] || exit 1
            ;;
    esac
}

validate_domain() {
    local domain=$1
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

validate_email() {
    local email=$1
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Input validation and collection
collect_inputs() {
    log_info "Collecting configuration information..."
    
    # WordPress admin user
    while true; do
        read -p "WordPress admin username: " username
        if [[ -n "$username" && "$username" != "admin" && "$username" != "administrator" ]]; then
            break
        fi
        log_warn "Avoid common usernames like 'admin'. Choose something unique."
    done
    
    # WordPress admin password
    while true; do
        read -sp "WordPress admin password (min 12 chars): " user_password
        echo
        if [[ ${#user_password} -ge 12 ]]; then
            break
        fi
        log_warn "Password must be at least 12 characters long"
    done
    
    # MySQL root password
    while true; do
        read -sp "MySQL root password (min 12 chars): " mysql_root_password
        echo
        if [[ ${#mysql_root_password} -ge 12 ]]; then
            break
        fi
        log_warn "MySQL password must be at least 12 characters long"
    done
    
    # Email for SSL certificates
    while true; do
        read -p "Email for SSL certificates: " ssl_email
        if validate_email "$ssl_email"; then
            break
        fi
        log_warn "Please enter a valid email address"
    done
    
    # Number of sites
    while true; do
        read -p "Number of WordPress sites to install (1-10): " num_sites
        if [[ "$num_sites" =~ ^[1-9]$|^10$ ]]; then
            break
        fi
        log_warn "Please enter a number between 1 and 10"
    done
    
    # Site configuration
    declare -gA sites db_passwords
    for i in $(seq 1 "$num_sites"); do
        while true; do
            read -p "Domain name for site $i (e.g., example.com): " domain
            if validate_domain "$domain"; then
                sites[$i]="$domain"
                break
            fi
            log_warn "Please enter a valid domain name"
        done
        
        while true; do
            read -sp "Database password for $domain (min 12 chars): " db_pass
            echo
            if [[ ${#db_pass} -ge 12 ]]; then
                db_passwords[$i]="$db_pass"
                break
            fi
            log_warn "Database password must be at least 12 characters long"
        done
    done
}

# System update and preparation
update_system() {
    log_info "Updating system packages..."
    apt update && apt upgrade -y
    apt autoremove -y
    apt autoclean
}

# Install modern software stack
install_software() {
    log_info "Installing modern software stack..."
    
    # Add repositories for latest software
    log_info "Adding software repositories..."
    
    # Nginx mainline repository
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
    
    # PHP 8.3 repository
    add-apt-repository ppa:ondrej/php -y
    
    # Redis repository for latest version
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor | tee /usr/share/keyrings/redis-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
    
    apt update
    
    # Install core packages
    log_info "Installing core packages..."
    apt install -y \
        nginx \
        "php${PHP_VERSION}-fpm" \
        "php${PHP_VERSION}-mysql" \
        "php${PHP_VERSION}-redis" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-gd" \
        "php${PHP_VERSION}-intl" \
        "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-xml" \
        "php${PHP_VERSION}-zip" \
        "php${PHP_VERSION}-bcmath" \
        "php${PHP_VERSION}-imagick" \
        "php${PHP_VERSION}-opcache" \
        mariadb-server \
        redis-server \
        certbot \
        python3-certbot-nginx \
        fail2ban \
        ufw \
        unattended-upgrades \
        htop \
        iotop \
        curl \
        wget \
        git \
        unzip \
        imagemagick \
        optipng \
        jpegoptim \
        webp \
        logwatch \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    # Install WP-CLI
    log_info "Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.10.0/utils/wp-completion.bash
    curl -L "https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar" -o /usr/local/bin/wp
    chmod +x /usr/local/bin/wp
    
    # Verify installations
    nginx -v || error_exit "Nginx installation failed"
    php${PHP_VERSION} -v || error_exit "PHP installation failed"
    mysql --version || error_exit "MariaDB installation failed"
    redis-server --version || error_exit "Redis installation failed"
    wp --version || error_exit "WP-CLI installation failed"
}

# Configure security
configure_security() {
    log_info "Configuring security settings..."
    
    # Configure UFW firewall
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 'Nginx Full'
    ufw --force enable
    
    # Configure fail2ban
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 2
EOF
    
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # Configure automatic security updates
    echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo 'Unattended-Upgrade::Remove-Unused-Dependencies "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    systemctl enable unattended-upgrades
    
    # Secure SSH
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
    systemctl restart ssh
}

# Configure PHP for performance and security
configure_php() {
    log_info "Configuring PHP ${PHP_VERSION} for optimal performance and security..."
    
    PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
    PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    
    # PHP.ini optimizations
    sed -i 's/;opcache.enable=1/opcache.enable=1/' "$PHP_INI"
    sed -i 's/;opcache.memory_consumption=128/opcache.memory_consumption=256/' "$PHP_INI"
    sed -i 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=20000/' "$PHP_INI"
    sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/' "$PHP_INI"
    sed -i 's/;opcache.save_comments=1/opcache.save_comments=1/' "$PHP_INI"
    
    # Security settings
    sed -i 's/expose_php = On/expose_php = Off/' "$PHP_INI"
    sed -i 's/allow_url_fopen = On/allow_url_fopen = Off/' "$PHP_INI"
    sed -i 's/;date.timezone =/date.timezone = UTC/' "$PHP_INI"
    
    # Performance settings
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' "$PHP_INI"
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' "$PHP_INI"
    sed -i 's/max_input_vars = 1000/max_input_vars = 3000/' "$PHP_INI"
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' "$PHP_INI"
    sed -i 's/post_max_size = 8M/post_max_size = 64M/' "$PHP_INI"
    
    # PHP-FPM optimizations
    sed -i 's/pm = dynamic/pm = ondemand/' "$PHP_FPM_CONF"
    sed -i 's/pm.max_children = 5/pm.max_children = 20/' "$PHP_FPM_CONF"
    sed -i 's/;pm.process_idle_timeout = 10s;/pm.process_idle_timeout = 10s/' "$PHP_FPM_CONF"
    
    systemctl restart "php${PHP_VERSION}-fpm"
}

# Configure Nginx for modern performance
configure_nginx() {
    log_info "Configuring Nginx for modern performance and security..."
    
    # Backup original config
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # Create optimized nginx.conf
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log crit;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    charset utf-8;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    server_tokens off;
    log_not_found off;
    types_hash_max_size 4096;
    client_max_body_size 64M;
    
    # MIME
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;
    
    # SSL
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # Modern TLS configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 valid=60s;
    resolver_timeout 2s;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Brotli compression (if available)
    # brotli on;
    # brotli_comp_level 6;
    # brotli_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=wp_login:10m rate=3r/m;
    limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=10r/m;
    
    # Include additional configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx config
    nginx -t || error_exit "Nginx configuration is invalid"
    
    systemctl restart nginx
}

# Configure Redis
configure_redis() {
    log_info "Configuring Redis for optimal performance..."
    
    # Redis configuration
    cat > /etc/redis/redis.conf << 'EOF'
# Network and basic settings
bind 127.0.0.1
port 6379
timeout 0
tcp-keepalive 300

# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence (optimized for caching)
save ""
appendonly no

# Security
requirepass REDIS_PASSWORD_PLACEHOLDER

# Performance
tcp-backlog 511
databases 16
EOF
    
    # Generate random Redis password
    REDIS_PASSWORD=$(openssl rand -base64 32)
    sed -i "s/REDIS_PASSWORD_PLACEHOLDER/$REDIS_PASSWORD/" /etc/redis/redis.conf
    
    # Save Redis password for later use
    echo "REDIS_PASSWORD='$REDIS_PASSWORD'" >> /root/.wp-setup-config
    chmod 600 /root/.wp-setup-config
    
    systemctl restart redis-server
    systemctl enable redis-server
}

# Configure MariaDB
configure_mariadb() {
    log_info "Configuring MariaDB for optimal performance and security..."
    
    systemctl start mariadb
    systemctl enable mariadb
    
    # Secure MariaDB installation
    mysql -e "UPDATE mysql.user SET Password = PASSWORD('$mysql_root_password') WHERE User = 'root'"
    mysql -e "DELETE FROM mysql.user WHERE User=''"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    mysql -e "DROP DATABASE IF EXISTS test"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -e "FLUSH PRIVILEGES"
    
    # Create MariaDB config for performance
    cat > /etc/mysql/mariadb.conf.d/99-wp-optimization.cnf << 'EOF'
[mysqld]
# Performance optimizations
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table = 1
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 2M
tmp_table_size = 32M
max_heap_table_size = 32M
max_connections = 100
thread_cache_size = 50
table_open_cache = 2000
EOF
    
    systemctl restart mariadb
}

# Install and configure WordPress sites
install_wordpress_sites() {
    log_info "Installing WordPress sites..."
    
    source /root/.wp-setup-config
    
    for i in $(seq 1 "$num_sites"); do
        site_name=${sites[$i]}
        db_password=${db_passwords[$i]}
        
        log_info "Setting up WordPress for $site_name..."
        
        # Create web directory
        mkdir -p "/var/www/$site_name"
        
        # Create Nginx configuration
        create_nginx_site_config "$site_name"
        
        # Enable site
        ln -sf "/etc/nginx/sites-available/$site_name" "/etc/nginx/sites-enabled/"
        
        # Test nginx and reload
        nginx -t && systemctl reload nginx
        
        # Install SSL certificate
        certbot --nginx -d "$site_name" -d "www.$site_name" \
            --non-interactive --agree-tos -m "$ssl_email" \
            --redirect || log_warn "SSL certificate installation failed for $site_name"
        
        # Download and install WordPress
        cd "/var/www/$site_name"
        wp core download --allow-root
        
        # Create database
        mysql -u root -p"$mysql_root_password" -e "CREATE DATABASE wp_${site_name//./_};"
        mysql -u root -p"$mysql_root_password" -e "CREATE USER 'wp_${site_name//./_}'@'localhost' IDENTIFIED BY '$db_password';"
        mysql -u root -p"$mysql_root_password" -e "GRANT ALL PRIVILEGES ON wp_${site_name//./_}.* TO 'wp_${site_name//./_}'@'localhost';"
        mysql -u root -p"$mysql_root_password" -e "FLUSH PRIVILEGES;"
        
        # Configure WordPress
        wp config create \
            --dbname="wp_${site_name//./_}" \
            --dbuser="wp_${site_name//./_}" \
            --dbpass="$db_password" \
            --dbhost="localhost" \
            --allow-root
        
        # Add Redis cache configuration
        cat >> wp-config.php << EOF

// Redis Cache Configuration
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_PASSWORD', '$REDIS_PASSWORD');
define('WP_REDIS_DATABASE', $i);
define('WP_CACHE_KEY_SALT', '${site_name}_');

// Security enhancements
define('DISALLOW_FILE_EDIT', true);
define('FORCE_SSL_ADMIN', true);
define('WP_AUTO_UPDATE_CORE', true);
EOF
        
        # Install WordPress
        wp core install \
            --url="https://$site_name" \
            --title="$site_name WordPress Site" \
            --admin_user="$username" \
            --admin_password="$user_password" \
            --admin_email="$ssl_email" \
            --allow-root
        
        # Install and configure essential plugins
        wp plugin install redis-cache --activate --allow-root
        wp plugin install wordfence --activate --allow-root
        wp plugin install updraftplus --activate --allow-root
        
        # Enable Redis cache
        wp redis enable --allow-root
        
        # Set proper permissions
        chown -R www-data:www-data "/var/www/$site_name"
        find "/var/www/$site_name" -type d -exec chmod 755 {} \;
        find "/var/www/$site_name" -type f -exec chmod 644 {} \;
        
        log_info "WordPress site $site_name installed successfully"
    done
}

# Create Nginx site configuration
create_nginx_site_config() {
    local site_name=$1
    
    cat > "/etc/nginx/sites-available/$site_name" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $site_name www.$site_name;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $site_name www.$site_name;
    
    root /var/www/$site_name;
    index index.php index.html index.htm;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # WordPress specific configurations
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # Handle PHP files
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # Security
        fastcgi_hide_header X-Powered-By;
    }
    
    # WordPress login rate limiting
    location ~ ^/(wp-admin|wp-login\.php) {
        limit_req zone=wp_login burst=3 nodelay;
        limit_req zone=wp_admin burst=10 nodelay;
        
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|zip)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
    }
    
    # Security: Block access to sensitive files
    location ~ /\. { deny all; }
    location ~ ~$ { deny all; }
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }
    location ~* ^/(wp-config\.php|wp-config\.txt|changelog\.txt|readme\.txt|readme\.html|license\.txt) { deny all; }
    
    # Block XML-RPC if not needed
    location = /xmlrpc.php { deny all; }
    
    # WordPress sitemap
    location ~ ([^/]*)sitemap(.*)\.x(m|s)l$ {
        try_files \$uri /index.php?\$args;
    }
}
EOF
}

# Setup monitoring and maintenance
setup_monitoring() {
    log_info "Setting up monitoring and maintenance..."
    
    # Configure logwatch
    cat > /etc/logwatch/conf/logwatch.conf << 'EOF'
MailTo = root
Detail = High
Range = yesterday
Service = All
Format = text
EOF
    
    # Setup cron jobs for maintenance
    cat > /etc/cron.d/wordpress-maintenance << 'EOF'
# SSL certificate renewal
0 2 * * * root /usr/bin/certbot renew --quiet

# WordPress updates (weekly)
0 3 * * 1 root /usr/local/bin/wp core update --allow-root --path=/var/www/*/

# Plugin updates (weekly)
0 4 * * 1 root find /var/www -name wp-config.php -execdir /usr/local/bin/wp plugin update --all --allow-root \;

# Database optimization (monthly)
0 2 1 * * root find /var/www -name wp-config.php -execdir /usr/local/bin/wp db optimize --allow-root \;

# Backup cleanup (keep 30 days)
0 5 * * * root find /var/backups/wordpress -name "*.tar.gz" -mtime +30 -delete

# System updates (daily security updates)
0 6 * * * root /usr/bin/unattended-upgrade
EOF
    
    # Create backup script
    cat > /usr/local/bin/wp-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/wordpress"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

for site_dir in /var/www/*/; do
    if [[ -f "$site_dir/wp-config.php" ]]; then
        site_name=$(basename "$site_dir")
        
        # Backup files
        tar -czf "$BACKUP_DIR/${site_name}_files_${DATE}.tar.gz" -C "/var/www" "$site_name"
        
        # Backup database
        cd "$site_dir"
        /usr/local/bin/wp db export "$BACKUP_DIR/${site_name}_db_${DATE}.sql" --allow-root
        gzip "$BACKUP_DIR/${site_name}_db_${DATE}.sql"
    fi
done

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
EOF
    
    chmod +x /usr/local/bin/wp-backup.sh
    
    # Add backup to cron
    echo "0 1 * * * root /usr/local/bin/wp-backup.sh" >> /etc/cron.d/wordpress-maintenance
}

# Check and create swap file for better memory management
check_and_create_swap() {
    log_info "Checking swap configuration..."
    
    if ! swapon --show | grep -q "/swapfile"; then
        log_info "Creating 2GB swap file for better memory management..."
        
        # Create swap file
        fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1024 count=2097152
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        
        # Make permanent
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        
        # Optimize swap usage
        echo 'vm.swappiness=10' >> /etc/sysctl.conf
        echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
        
        log_info "Swap file created and configured successfully"
    else
        log_info "Swap already configured"
    fi
}

# Validate system resources
check_system_resources() {
    log_info "Checking system resources..."
    
    # Check RAM (minimum 2GB recommended)
    total_ram=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_ram" -lt 1900 ]; then
        log_warn "Warning: Only ${total_ram}MB RAM available. 2GB+ recommended for optimal performance"
        log_warn "Consider upgrading your server or enabling swap for better stability"
    else
        log_info "RAM: ${total_ram}MB available - Good"
    fi
    
    # Check disk space (minimum 20GB recommended)
    available_space_gb=$(df / | awk 'NR==2{printf "%.1f", $4/1024/1024}')
    available_space_kb=$(df / | awk 'NR==2{print $4}')
    
    if [ "$available_space_kb" -lt 20971520 ]; then  # 20GB in KB
        log_warn "Warning: Only ${available_space_gb}GB disk space available. 20GB+ recommended"
    else
        log_info "Disk space: ${available_space_gb}GB available - Good"
    fi
    
    # Check CPU cores
    cpu_cores=$(nproc)
    log_info "CPU cores: $cpu_cores available"
}

# Setup log rotation for better disk space management
setup_log_rotation() {
    log_info "Configuring log rotation..."
    
    # Nginx log rotation
    cat > /etc/logrotate.d/nginx-wordpress << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    sharedscripts
    postrotate
        systemctl reload nginx
    endscript
}
EOF

    # PHP-FPM log rotation
    cat > /etc/logrotate.d/php-fpm-wordpress << 'EOF'
/var/log/php8.3-fpm.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    postrotate
        systemctl reload php8.3-fpm
    endscript
}
EOF

    # WordPress debug log rotation
    cat > /etc/logrotate.d/wordpress-debug << 'EOF'
/var/www/*/wp-content/debug.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
}
EOF

    log_info "Log rotation configured successfully"
}

# Configure timezone
configure_timezone() {
    log_info "Configuring system timezone..."
    
    # Show current timezone
    current_tz=$(timedatectl show --property=Timezone --value)
    log_info "Current timezone: $current_tz"
    
    # Ask user for timezone preference
    echo "Common timezones:"
    echo "  1. UTC (default)"
    echo "  2. America/New_York (Eastern US)"
    echo "  3. America/Chicago (Central US)"
    echo "  4. America/Denver (Mountain US)"
    echo "  5. America/Los_Angeles (Pacific US)"
    echo "  6. Europe/London (UK)"
    echo "  7. Europe/Paris (Central Europe)"
    echo "  8. Asia/Tokyo (Japan)"
    echo "  9. Custom timezone"
    
    read -p "Select timezone option (1-9) [1]: " tz_choice
    tz_choice=${tz_choice:-1}
    
    case $tz_choice in
        1) user_timezone="UTC" ;;
        2) user_timezone="America/New_York" ;;
        3) user_timezone="America/Chicago" ;;
        4) user_timezone="America/Denver" ;;
        5) user_timezone="America/Los_Angeles" ;;
        6) user_timezone="Europe/London" ;;
        7) user_timezone="Europe/Paris" ;;
        8) user_timezone="Asia/Tokyo" ;;
        9) 
            read -p "Enter custom timezone (e.g., Asia/Shanghai): " user_timezone
            ;;
        *) 
            log_warn "Invalid choice, keeping UTC"
            user_timezone="UTC"
            ;;
    esac
    
    if [[ -f "/usr/share/zoneinfo/$user_timezone" ]]; then
        timedatectl set-timezone "$user_timezone"
        # Update PHP timezone too
        sed -i "s|date.timezone = UTC|date.timezone = $user_timezone|" /etc/php/${PHP_VERSION}/fpm/php.ini
        systemctl restart "php${PHP_VERSION}-fpm"
        log_info "Timezone set to $user_timezone"
    else
        log_warn "Invalid timezone '$user_timezone', keeping UTC"
    fi
}

# Setup basic email monitoring
setup_email_monitoring() {
    log_info "Setting up basic email monitoring..."
    
    # Install postfix for basic email functionality
    echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive apt-get install -y postfix mailutils
    
    # Configure basic postfix
    postconf -e "inet_protocols = ipv4"
    postconf -e "mydestination = localhost"
    systemctl restart postfix
    
    # Create disk space monitoring script
    cat > /usr/local/bin/disk-monitor.sh << 'EOF'
#!/bin/bash
THRESHOLD=85
EMAIL="root@localhost"

df -h | awk '{print $5 " " $1}' | while read output; do
    percentage=$(echo $output | awk '{print $1}' | sed 's/%//g')
    partition=$(echo $output | awk '{print $2}')
    
    if [ ! -z "$percentage" ] && [ "$percentage" -ge "$THRESHOLD" ] 2>/dev/null; then
        echo "WARNING: Disk space on $partition is ${percentage}% full" | mail -s "Disk Space Alert - $(hostname)" $EMAIL
    fi
done
EOF
    chmod +x /usr/local/bin/disk-monitor.sh
    
    # Create service monitoring script
    cat > /usr/local/bin/service-monitor.sh << 'EOF'
#!/bin/bash
SERVICES="nginx php8.3-fpm mariadb redis-server"
EMAIL="root@localhost"

for service in $SERVICES; do
    if ! systemctl is-active --quiet $service; then
        echo "WARNING: Service $service is not running on $(hostname)" | mail -s "Service Alert - $service Down" $EMAIL
    fi
done
EOF
    chmod +x /usr/local/bin/service-monitor.sh
    
    # Add monitoring to cron
    echo "0 6 * * * root /usr/local/bin/disk-monitor.sh" >> /etc/cron.d/wordpress-maintenance
    echo "*/15 * * * * root /usr/local/bin/service-monitor.sh" >> /etc/cron.d/wordpress-maintenance
    
    log_info "Email monitoring configured (alerts sent to root@localhost)"
}

# Optimize database configuration
optimize_database() {
    log_info "Optimizing MariaDB configuration..."
    
    # Get available RAM for optimization
    total_ram_mb=$(free -m | awk 'NR==2{print $2}')
    
    # Calculate InnoDB buffer pool size (50-70% of RAM)
    if [ "$total_ram_mb" -gt 4000 ]; then
        innodb_buffer_pool_size="2G"
    elif [ "$total_ram_mb" -gt 2000 ]; then
        innodb_buffer_pool_size="1G"
    else
        innodb_buffer_pool_size="512M"
    fi
    
    # Create optimized MySQL configuration
    cat > /etc/mysql/conf.d/wordpress-optimized.cnf << EOF
[mysqld]
# WordPress optimizations
query_cache_type = 1
query_cache_limit = 256K
query_cache_min_res_unit = 2k
query_cache_size = 80M

# InnoDB optimizations
innodb_buffer_pool_size = $innodb_buffer_pool_size
innodb_log_file_size = 64M
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_flush_log_at_trx_commit = 2

# Connection optimizations
max_connections = 151
thread_cache_size = 8
table_open_cache = 64
tmp_table_size = 32M
max_heap_table_size = 32M

# Slow query log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Security
local_infile = 0
EOF

    systemctl restart mariadb
    log_info "Database optimized for available system resources"
}

# Additional WordPress security hardening
additional_wp_security() {
    log_info "Applying additional WordPress security hardening..."
    
    for i in $(seq 1 "$num_sites"); do
        site_name="${sites[$i]}"
        site_dir="/var/www/$site_name"
        
        if [[ -f "$site_dir/wp-config.php" ]]; then
            cd "$site_dir"
            
            # Disable file editing in WordPress admin
            if ! grep -q "DISALLOW_FILE_EDIT" wp-config.php; then
                sed -i "/\/\* That's all, stop editing/i define('DISALLOW_FILE_EDIT', true);" wp-config.php
            fi
            
            # Force SSL
            if ! grep -q "FORCE_SSL_ADMIN" wp-config.php; then
                sed -i "/\/\* That's all, stop editing/i define('FORCE_SSL_ADMIN', true);" wp-config.php
            fi
            
            # Disable WordPress debug display (keep logging)
            sed -i "s/define('WP_DEBUG_DISPLAY', true)/define('WP_DEBUG_DISPLAY', false)/" wp-config.php
            
            # Set secure WordPress salts
            wp config shuffle-salts --allow-root
            
            # Create .htaccess for additional security (if not exists)
            if [[ ! -f ".htaccess" ]]; then
                cat > .htaccess << 'EOF'
# Security headers
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options SAMEORIGIN
    Header always set X-XSS-Protection "1; mode=block"
</IfModule>

# Block access to sensitive files
<Files wp-config.php>
    order allow,deny
    deny from all
</Files>

<Files .htaccess>
    order allow,deny
    deny from all
</Files>

# WordPress security
RewriteEngine On
RewriteRule ^wp-admin/includes/ - [F,L]
RewriteRule !^wp-includes/ - [S=3]
RewriteRule ^wp-includes/[^/]+\.php$ - [F,L]
RewriteRule ^wp-includes/js/tinymce/langs/.+\.php - [F,L]
RewriteRule ^wp-includes/theme-compat/ - [F,L]
EOF
                chown www-data:www-data .htaccess
            fi
            
            log_info "Security hardening applied to $site_name"
        fi
    done
}

# Test SSL certificate renewal
test_ssl_renewal() {
    log_info "Testing SSL certificate auto-renewal..."
    
    if command -v certbot >/dev/null 2>&1; then
        if certbot renew --dry-run; then
            log_info "SSL renewal test passed successfully"
        else
            log_warn "SSL renewal test failed - check certbot configuration"
        fi
    else
        log_warn "Certbot not found - SSL renewal test skipped"
    fi
}

# Setup basic system monitoring
setup_system_monitoring() {
    log_info "Setting up system health monitoring..."
    
    # Install basic monitoring tools
    apt-get install -y htop iotop nethogs ncdu
    
    # Create system health check script
    cat > /usr/local/bin/system-health.sh << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/system-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== System Health Report $DATE ===" >> $LOG_FILE

# CPU and Load Average
echo "Load Average:" >> $LOG_FILE
uptime >> $LOG_FILE

# Memory Usage
echo "Memory Usage:" >> $LOG_FILE
free -h >> $LOG_FILE

# Disk Usage
echo "Disk Usage:" >> $LOG_FILE
df -h >> $LOG_FILE

# Service Status
echo "Critical Services:" >> $LOG_FILE
for service in nginx php8.3-fpm mariadb redis-server; do
    if systemctl is-active --quiet $service; then
        echo "$service: RUNNING" >> $LOG_FILE
    else
        echo "$service: STOPPED" >> $LOG_FILE
    fi
done

# Network connections
echo "Active Connections:" >> $LOG_FILE
ss -tuln | grep -E ':(80|443|22|3306)' >> $LOG_FILE

echo "---" >> $LOG_FILE

# Rotate log if it gets too large (keep last 1000 lines)
if [ -f "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi
EOF
    chmod +x /usr/local/bin/system-health.sh
    
    # Add to cron (every 6 hours)
    echo "0 */6 * * * root /usr/local/bin/system-health.sh" >> /etc/cron.d/wordpress-maintenance
    
    log_info "System monitoring configured"
}

# Main execution
main() {
    check_root
    check_os
    check_system_resources
    configure_timezone
    collect_inputs
    
    log_info "Starting WordPress installation with modern stack..."
    
    update_system
    check_and_create_swap
    install_software
    configure_security
    configure_php
    configure_nginx
    configure_redis
    configure_mariadb
    optimize_database
    install_wordpress_sites
    additional_wp_security
    setup_log_rotation
    setup_email_monitoring
    setup_system_monitoring
    setup_monitoring
    test_ssl_renewal
    
    log_info "Installation completed successfully!"
    log_info "WordPress sites are now available:"
    
    for i in $(seq 1 "$num_sites"); do
        echo "  - https://${sites[$i]}"
    done
    
    echo
    log_info "Configuration saved to: /root/.wp-setup-config"
    log_info "Setup log saved to: $LOG_FILE"
    log_info "Admin username: $username"
    echo
    log_info "Next steps:"
    echo "1. Configure your DNS to point to this server"
    echo "2. Access your WordPress admin at: https://${sites[1]}/wp-admin"
    echo "3. Review security plugins and configure backups"
    echo "4. Set up monitoring and alerts"
    
    # Display system information
    echo
    log_info "System Information:"
    echo "PHP Version: $(php${PHP_VERSION} -v | head -n1)"
    echo "Nginx Version: $(nginx -v 2>&1)"
    echo "MariaDB Version: $(mysql --version)"
    echo "Redis Version: $(redis-server --version)"
    echo "WP-CLI Version: $(wp --version)"
}

# Run main function
main "$@"
