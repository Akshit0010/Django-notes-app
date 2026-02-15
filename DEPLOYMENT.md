# Production Deployment Guide

This guide provides detailed instructions for deploying the Django Notes application to production.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Docker Deployment](#docker-deployment)
3. [Manual Deployment on Ubuntu](#manual-deployment-on-ubuntu)
4. [AWS EC2 Deployment](#aws-ec2-deployment)
5. [Security Hardening](#security-hardening)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Backup Strategy](#backup-strategy)

## Pre-Deployment Checklist

Before deploying to production, ensure you have:

- [ ] Generated a strong SECRET_KEY
- [ ] Set DEBUG=False
- [ ] Configured ALLOWED_HOSTS with your domain
- [ ] Set up strong database passwords
- [ ] Configured SSL/TLS certificates
- [ ] Set up firewall rules
- [ ] Prepared backup strategy
- [ ] Set up monitoring tools
- [ ] Reviewed security settings
- [ ] Tested application locally

## Docker Deployment

### Quick Setup

1. **Prepare the server:**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose git -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

2. **Clone and configure:**

```bash
git clone <your-repo-url> /opt/django-notes-app
cd /opt/django-notes-app
cp .env.example .env
nano .env  # Edit with production values
```

3. **Deploy:**

```bash
docker-compose up -d --build
```

### Production Environment Variables

```env
SECRET_KEY=<generate-with-python-script>
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

DB_NAME=notes_db
DB_USER=notes_user
DB_PASSWORD=<strong-random-password>
DB_HOST=db
DB_PORT=3306

MYSQL_ROOT_PASSWORD=<strong-random-password>
```

### Generate Secret Key

```bash
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

## Manual Deployment on Ubuntu

### System Requirements

- Ubuntu 20.04 LTS or 22.04 LTS
- 2GB+ RAM
- 20GB+ disk space
- Root or sudo access

### Step-by-Step Installation

#### 1. System Update

```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Install Required Packages

```bash
sudo apt install -y python3.11 python3.11-venv python3-pip \
    mysql-server mysql-client libmysqlclient-dev \
    nginx build-essential pkg-config git
```

#### 3. Configure MySQL

```bash
sudo mysql_secure_installation
sudo mysql -u root -p
```

MySQL commands:

```sql
CREATE DATABASE notes_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'notes_user'@'localhost' IDENTIFIED BY 'SecurePassword123!';
GRANT ALL PRIVILEGES ON notes_db.* TO 'notes_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 4. Application Setup

```bash
cd /opt
sudo git clone <your-repo-url> django-notes-app
cd django-notes-app
sudo python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 5. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update with production values.

#### 6. Django Setup

```bash
python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic --noinput
```

#### 7. Gunicorn Service

Create `/etc/systemd/system/gunicorn.service`:

```ini
[Unit]
Description=Gunicorn daemon for Django Notes App
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/django-notes-app
Environment="PATH=/opt/django-notes-app/venv/bin"
EnvironmentFile=/opt/django-notes-app/.env
ExecStart=/opt/django-notes-app/venv/bin/gunicorn \
          --config /opt/django-notes-app/gunicorn_config.py \
          notesproject.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo chown -R www-data:www-data /opt/django-notes-app
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
```

#### 8. Nginx Configuration

Create `/etc/nginx/sites-available/django-notes`:

```nginx
upstream django_app {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    client_max_body_size 10M;

    location / {
        proxy_pass http://django_app;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
    }

    location /static/ {
        alias /opt/django-notes-app/staticfiles/;
    }

    location /media/ {
        alias /opt/django-notes-app/media/;
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/django-notes /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## AWS EC2 Deployment

### Launch EC2 Instance

1. Choose Ubuntu Server 22.04 LTS
2. Instance type: t2.small or larger
3. Configure security group:
   - SSH (22) - Your IP
   - HTTP (80) - Anywhere
   - HTTPS (443) - Anywhere

### Deploy with Docker

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Docker
sudo apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo apt install docker-compose -y

# Deploy application
git clone <your-repo-url> django-notes-app
cd django-notes-app
cp .env.example .env
nano .env  # Update with production values
docker-compose up -d --build
```

### Configure Domain

1. Point your domain's A record to EC2 IP
2. Update ALLOWED_HOSTS in .env
3. Restart containers: `docker-compose restart`

## Security Hardening

### 1. SSL/TLS Configuration

Install Certbot:

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 2. Firewall Setup

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### 3. Database Security

Edit MySQL configuration:

```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

Add:

```ini
bind-address = 127.0.0.1
```

Restart MySQL:

```bash
sudo systemctl restart mysql
```

### 4. Django Security Settings

In production settings, ensure:

```python
DEBUG = False
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
```

### 5. Fail2Ban Setup

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Monitoring and Logging

### Application Logs

```bash
# Docker deployment
docker-compose logs -f web

# Manual deployment
sudo journalctl -u gunicorn -f
```

### Nginx Logs

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Database Logs

```bash
sudo tail -f /var/log/mysql/error.log
```

### Set Up Log Rotation

Create `/etc/logrotate.d/django-notes`:

```
/opt/django-notes-app/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
}
```

## Backup Strategy

### Database Backup Script

Create `/opt/backup-db.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Docker deployment
docker-compose exec -T db mysqldump -u notes_user -p$DB_PASSWORD notes_db > $BACKUP_DIR/notes_db_$DATE.sql

# Manual deployment
# mysqldump -u notes_user -p notes_db > $BACKUP_DIR/notes_db_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "notes_db_*.sql" -mtime +7 -delete

echo "Backup completed: notes_db_$DATE.sql"
```

Make executable:

```bash
sudo chmod +x /opt/backup-db.sh
```

### Schedule Daily Backups

```bash
sudo crontab -e
```

Add:

```
0 2 * * * /opt/backup-db.sh
```

### Application Code Backup

```bash
tar -czf /opt/backups/app_$(date +%Y%m%d).tar.gz /opt/django-notes-app
```

## Maintenance Tasks

### Update Application

```bash
# Docker deployment
cd /opt/django-notes-app
git pull origin main
docker-compose down
docker-compose up -d --build

# Manual deployment
cd /opt/django-notes-app
source venv/bin/activate
git pull origin main
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart gunicorn
```

### Database Migrations

```bash
# Docker
docker-compose exec web python manage.py migrate

# Manual
python manage.py migrate
```

### Check System Health

```bash
# Check services
sudo systemctl status gunicorn
sudo systemctl status nginx
sudo systemctl status mysql

# Check disk space
df -h

# Check memory
free -h

# Check processes
top
```

## Troubleshooting

### Application Won't Start

```bash
# Check logs
docker-compose logs web

# Or
sudo journalctl -u gunicorn -xe
```

### Database Connection Issues

```bash
# Test MySQL connection
mysql -u notes_user -p notes_db

# Check MySQL status
sudo systemctl status mysql
```

### Static Files Not Loading

```bash
# Recollect static files
docker-compose exec web python manage.py collectstatic --noinput

# Check Nginx configuration
sudo nginx -t
```

### SSL Certificate Issues

```bash
# Renew certificate
sudo certbot renew --dry-run
```

## Performance Optimization

### Enable Nginx Caching

Add to Nginx config:

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g
                 inactive=60m use_temp_path=off;

location / {
    proxy_cache my_cache;
    proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
    proxy_pass http://django_app;
}
```

### Database Optimization

```sql
OPTIMIZE TABLE notes_note;
ANALYZE TABLE notes_note;
```

### Gunicorn Workers

Adjust in `gunicorn_config.py`:

```python
workers = (2 * cpu_count) + 1
```

## Disaster Recovery

### Full System Restore

1. Install fresh system
2. Install dependencies
3. Restore database: `mysql -u notes_user -p notes_db < backup.sql`
4. Restore application code
5. Configure services
6. Restart all services

---

For additional help, refer to the main README.md or create an issue on GitHub.
