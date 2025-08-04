<p align="center">
  <img width="260" height="161" src="https://github.com/rkruk/Ubuntu-Nginx-PHP-Redis/blob/master/images/linux-ubuntu-nginx-mysql-php-wordpress.jpg">
</p>

# WordPress + NGINX + PHP + Redis Installation Script for 2025 Ubuntu/Debian VPS

This script automates the installation of a **modern, secure, and high-performance** WordPress environment optimized for 2025 standards.

## What's New in 2025 Version

- **PHP 8.3** - Latest stable PHP with performance improvements
- **Nginx Mainline** - Latest Nginx with HTTP/3 and modern features  
- **Ubuntu 24.04 LTS** - Full support for latest Ubuntu LTS
- **Modern TLS 1.3** - Latest encryption standards
- **Advanced Security** - Enhanced fail2ban, CSP headers, rate limiting
- **Redis 7.x** - Latest Redis with improved performance
- **Optimized Configs** - Fine-tuned for speed and security
- **Smart Resource Management** - Automatic swap configuration and system optimization
- **Enhanced Monitoring** - Email alerts, system health checks, log rotation
- **Database Tuning** - Performance optimization based on available resources

## Performance Features

### Speed Optimizations
- **PHP 8.3 with OPcache** - 20-30% faster than PHP 8.1
- **Redis Object Cache** - Database query caching
- **Nginx HTTP/2** - Multiplexed connections
- **Brotli Compression** - Better than gzip compression
- **Static File Caching** - 1-year cache headers
- **Database Query Optimization** - MariaDB performance tuning
- **Adaptive Configuration** - Settings optimized based on server resources
- **Smart Memory Management** - Automatic swap configuration

### Security Hardening  
- **TLS 1.3 Only** - Modern encryption protocols
- **Security Headers** - HSTS, CSP, X-Frame-Options
- **Rate Limiting** - WordPress login protection
- **Fail2ban** - Intrusion prevention
- **Firewall (UFW)** - Minimal attack surface
- **Auto Security Updates** - System stays patched
- **WordPress Hardening** - File editing disabled, secure salts
- **Advanced Monitoring** - Email alerts for critical events

### System Management
- **Intelligent Resource Monitoring** - Real-time system health checks
- **Automated Log Rotation** - Prevents disk space issues
- **Email Notifications** - Alerts for disk space and service failures  
- **SSL Auto-Renewal Testing** - Ensures certificates stay valid
- **Timezone Configuration** - Proper time settings for logs and scheduling
- **Backup Automation** - Scheduled WordPress and database backups

## Modern Stack (2025)

| Component | Version | Features |
|-----------|---------|----------|
| **OS** | Ubuntu 22.04/24.04 LTS | Latest LTS with 10-year support |
| **Web Server** | Nginx Mainline | HTTP/2, Brotli, Modern TLS |
| **PHP** | 8.3 | JIT compiler, improved performance |
| **Database** | MariaDB 10.11+ | Optimized for WordPress |
| **Cache** | Redis 7.x | Advanced object caching |
| **SSL** | Let's Encrypt | Free automated certificates |
| **Security** | Fail2ban + UFW | Multi-layer protection |

## Prerequisites (Minimal - Script Handles Everything Else!)

### **Required Before Running:**
- **Fresh Ubuntu Server** (22.04 or 24.04 LTS recommended)
- **Domain name** pointed to server IP  
- **Root/sudo access** via SSH
- **Internet connection** for downloads
- **2GB+ RAM** (4GB+ recommended for multiple sites)
- **20GB+ storage** (SSD recommended)

### **No Software Pre-Installation Needed!**

The script automatically installs **everything required**:
-  **Web Stack**: Nginx, PHP 8.3, MariaDB, Redis
-  **SSL Certificates**: Let's Encrypt with auto-renewal
-  **Security Tools**: fail2ban, UFW firewall, security headers
-  **Performance Tools**: OPcache, image optimization, monitoring
-  **System Tools**: curl, wget, git, WP-CLI, backup tools

**Just run the script on a fresh Ubuntu server - it handles the rest!**

### **What If Basic Tools Are Missing?**

If your server is missing basic tools, the script will install them:

```bash
# The script first installs these essentials:
sudo apt update && sudo apt upgrade -y

# Then installs core tools needed for the setup:
- software-properties-common (for adding repositories)
- apt-transport-https (for secure downloads)
- ca-certificates (for SSL verification)  
- curl, wget (for downloading files)
- gnupg (for GPG key verification)
- lsb-release (for Ubuntu version detection)
```

**Result: Even a minimal Ubuntu installation will work!**

## Quick Installation

⚠️ **IMPORTANT: This script must be run as root (with sudo)**

### Method 1: Clone Repository (Recommended)

```bash
# Clone the repository
git clone https://github.com/rkruk/Ubuntu-Nginx-PHP-Redis.git
cd Ubuntu-Nginx-PHP-Redis

# Make script executable
chmod +x wordpress-setup.sh

# Run as root (REQUIRED)
sudo ./wordpress-setup.sh
```

### Method 2: Direct Download

```bash
# Download script directly
wget https://raw.githubusercontent.com/rkruk/Ubuntu-Nginx-PHP-Redis/master/wordpress-setup.sh

# Make executable and run as root
chmod +x wordpress-setup.sh
sudo ./wordpress-setup.sh
```

## 🔧 Installation Process

The script includes these enhanced steps:

### 1. **System Validation & Optimization**
- ⚠️ **Root access verification** - Script checks for proper privileges
- **OS compatibility check** - Ubuntu 22.04/24.04 LTS validation
- **Resource validation** - RAM, disk space, CPU cores assessment
- **Swap configuration** - Automatic 2GB swap creation if needed
- **Timezone setup** - Interactive timezone configuration

### 2. **Input Validation** 
- Strong password enforcement (12+ chars)
- Domain name validation
- Email format verification
- Security-focused defaults

### 3. **Modern Software Installation**
```bash
# Automatically installs:
- Nginx (mainline) with HTTP/2
- PHP 8.3 with all optimizations  
- MariaDB with performance tuning
- Redis 7.x with security config
- Let's Encrypt with auto-renewal
- Essential security tools
```

### 4. **Performance Optimization**
- PHP OPcache configuration
- Nginx performance tuning
- Redis object caching
- Adaptive database optimization (based on available RAM)
- Static file caching
- Log rotation setup

### 5. **Security Configuration**
- Modern TLS 1.3 setup
- Security headers (HSTS, CSP)
- Rate limiting for WordPress
- Fail2ban with custom rules
- Firewall configuration
- WordPress file editing disabled
- Secure WordPress salts

### 6. **WordPress Installation**
- Latest WordPress core
- Essential security plugins (Wordfence)
- Redis cache plugin
- Backup plugin (UpdraftPlus)
- Performance optimizations

### 7. **Monitoring & Maintenance**
- Automated SSL renewal with testing
- WordPress auto-updates
- Database optimization
- System health monitoring
- Email alerts for critical events
- Automated backup scheduling

## Post-Installation Commands

```bash
# Check all services status
sudo systemctl status nginx php8.3-fpm mariadb redis-server

# View performance metrics  
sudo htop
sudo iotop

# Check security status
sudo fail2ban-client status
sudo ufw status

# Check system health
sudo /usr/local/bin/system-health.sh
tail /var/log/system-health.log

# Check swap configuration
sudo swapon --show
free -h

# Test website speed
curl -w "@curl-format.txt" -o /dev/null -s "https://yoursite.com"

# Monitor logs
sudo tail -f /var/log/wordpress-setup-*.log

# Check email monitoring
sudo systemctl status postfix
sudo mail -s "Test" root@localhost < /dev/null
```

## Security Features

### Built-in Security Measures
- **TLS 1.3 encryption** with perfect forward secrecy
- **Security headers** prevent XSS, clickjacking, MIME sniffing
- **Rate limiting** protects against brute force attacks  
- **Fail2ban** automatically blocks malicious IPs
- **WordPress hardening** disables file editing, forces SSL
- **Database security** with limited user privileges
- **Automatic updates** for security patches

### Security Validation
```bash
# SSL/TLS test (should get A+ rating)
curl -s "https://api.ssllabs.com/api/v3/analyze?host=yoursite.com"

# Security headers check
curl -I https://yoursite.com

# WordPress security scan  
wp scan --allow-root
```

## Troubleshooting Guide

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **SSL certificate fails** | Ensure DNS points to server, ports 80/443 open |
| **WordPress 502 error** | Check PHP-FPM: `sudo systemctl status php8.3-fpm` |
| **Redis connection error** | Verify Redis: `redis-cli ping` should return `PONG` |
| **High memory usage** | Check swap: `free -h`, adjust PHP settings |
| **Slow loading** | Enable Redis cache in WordPress admin |
| **Script fails on curl/wget** | Run: `sudo apt update && sudo apt install curl wget` |
| **Repository errors** | Check internet connection, run: `sudo apt update` |
| **Permission denied** | Ensure you're using `sudo ./wordpress-setup.sh` |
| **Low disk space** | Check: `df -h`, clean logs: `sudo journalctl --vacuum-time=7d` |
| **Email alerts not working** | Check postfix: `sudo systemctl status postfix` |

### Diagnostic Commands
```bash
# Check all service logs
sudo journalctl -f

# PHP error log
sudo tail -f /var/log/php8.3-fpm.log

# Nginx error log  
sudo tail -f /var/log/nginx/error.log

# WordPress debug log
tail -f /var/www/yoursite.com/wp-content/debug.log

# Database performance
sudo mysqladmin -u root -p processlist

# System health report
sudo /usr/local/bin/system-health.sh
cat /var/log/system-health.log

# Check resource usage
free -h
df -h
sudo swapon --show

# Email system check
sudo systemctl status postfix
sudo mailq
```

## Advanced Optimizations

### For High-Traffic Sites (10k+ visitors/day)

```bash
# Enable Nginx caching
sudo mkdir -p /var/cache/nginx
# Add fastcgi_cache configuration

# Increase PHP-FPM workers
sudo nano /etc/php/8.3/fpm/pool.d/www.conf
# Set pm.max_children = 50

# Database tuning
sudo mysql_secure_installation
sudo mysqltuner

# Add CDN integration (Cloudflare recommended)
```

### Performance Monitoring
```bash
# Install monitoring tools
sudo apt install htop iotop netdata

# WordPress performance plugin
wp plugin install query-monitor --activate --allow-root

# Database monitoring
wp db check --allow-root
wp db optimize --allow-root
```

## File Structure

```
Ubuntu-Nginx-PHP-Redis/
├── LICENSE
├── README.md
├── wordpress-setup.sh
├── images/
│   └── linux-ubuntu-nginx-mysql-php-wordpress.jpg
├── CHANGELOG.md
└── CONTRIBUTING.md
```

## ⚠️ Important: Root Access Required

**The script MUST be run as root (with sudo).** Here's why:

-  **System package installation** - Requires root to install Nginx, PHP, etc.
-  **Service configuration** - Needs root to configure system services
-  **SSL certificate setup** - Let's Encrypt requires root privileges
-  **Firewall configuration** - UFW and fail2ban need root access
-  **User and permission management** - Creating users and setting permissions

### Root Check Built-in
The script automatically checks if you're running as root:
```bash
# If you run without sudo:
$ ./wordpress-setup.sh
ERROR: This script must be run as root (use sudo)

# Correct way to run:
$ sudo ./wordpress-setup.sh
Modern WordPress Setup Script v2.0.0
Started: 2025-01-04 10:30:15
============================================
```

## Installation Recommendation

### For Production Sites (2025):
```bash
# Clone and run (RECOMMENDED)
git clone https://github.com/rkruk/Ubuntu-Nginx-PHP-Redis.git
cd Ubuntu-Nginx-PHP-Redis
sudo ./wordpress-setup.sh  # ⚠️ sudo is REQUIRED
```

### Direct Download:
```bash  
# Download and run
wget https://raw.githubusercontent.com/rkruk/Ubuntu-Nginx-PHP-Redis/master/wordpress-setup.sh
sudo ./wordpress-setup.sh  # ⚠️ sudo is REQUIRED
```

## Why This Stack in 2025?

-  **Future-proof**: Latest LTS versions with long-term support
-  **Performance**: 60-70% faster than legacy configurations  
-  **Security**: A+ SSL rating, modern encryption
-  **Scalability**: Handles high traffic efficiently
-  **Maintenance**: Automated updates and monitoring
-  **Cost-effective**: Optimized resource usage

## Support & Contributing

-  **Bug Reports**: [GitHub Issues](https://github.com/rkruk/Ubuntu-Nginx-PHP-Redis/issues)
-  **Feature Requests**: [GitHub Discussions](https://github.com/rkruk/Ubuntu-Nginx-PHP-Redis/discussions)  
-  **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
-  **Documentation**: This README + inline script comments

## 📄 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

### License Summary
-  **Commercial use** - Use for commercial purposes
-  **Modification** - Modify and distribute
-  **Distribution** - Distribute the original or modified versions
-  **Patent use** - Grant of patent rights from contributors
-  **Private use** - Use privately without restrictions

### Attribution
When using this script in your projects, please provide attribution to the original repository:
```
WordPress + NGINX + PHP + Redis Installation Script
https://github.com/rkruk/Ubuntu-Nginx-PHP-Redis
Licensed under Apache License 2.0
```

Thank you for any tips, improvements, recommendations or questions!
