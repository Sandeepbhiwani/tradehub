# TradeHub - Live VPS Production Deployment Guide

Complete step-by-step guide for deploying TradeHub Django application on VPS (209.74.82.4)

---

## 📋 Prerequisites

Before starting, you need:
- SSH access to VPS: `ssh -p 22022 root@209.74.82.4`
- Password: `@Akm12109`
- Ubuntu 24.04 LTS (or similar)
- Domain name (optional, but recommended)
- 2GB+ RAM, 20GB+ disk space

---

## 🚀 Quick Start (Automated)

### Method 1: One-Click Deployment (Easiest)

1. **SSH into your VPS:**
```bash
ssh -p 22022 root@209.74.82.4
```

2. **Clone the repository:**
```bash
cd /tmp
git clone https://github.com/Sandeepbhiwani/tradehub tradehub-setup
cd tradehub-setup
```

3. **Run the deployment script:**
```bash
chmod +x deploy.sh
sudo ./deploy.sh
```

The script will:
- ✅ Install all system dependencies
- ✅ Setup PostgreSQL database
- ✅ Configure Python virtual environment
- ✅ Configure Gunicorn service
- ✅ Setup Nginx as reverse proxy
- ✅ Configure SSL/HTTPS
- ✅ Create systemd service for auto-restart
- ✅ Setup logging

---

## 🔧 Manual Deployment (Step-by-Step)

If you prefer to do it manually, follow these steps:

### Step 1: SSH and Update System

```bash
ssh -p 22022 root@209.74.82.4

# Update system packages
apt-get update && apt-get upgrade -y

# Install required packages
apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib \
    nginx supervisor \
    git curl wget \
    build-essential libpq-dev \
    certbot python3-certbot-nginx
```

### Step 2: Create Project Directory

```bash
mkdir -p /var/www/tradehub
cd /var/www/tradehub
```

### Step 3: Clone/Copy Project

```bash
# Option A: Clone from Git
git clone https://github.com/Sandeepbhiwani/tradehub .

# Option B: Copy from local (from your local machine)
# scp -P 22022 -r /path/to/tradehub/* root@209.74.82.4:/var/www/tradehub/
```

### Step 4: Setup Python Virtual Environment

```bash
cd /var/www/tradehub
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

### Step 5: Setup PostgreSQL Database

```bash
# Login to PostgreSQL
sudo -u postgres psql

# In PostgreSQL prompt, run:
CREATE DATABASE tradehub_db;
CREATE USER tradehub_user WITH PASSWORD 'SecurePassword123!';
ALTER ROLE tradehub_user SET client_encoding TO 'utf8';
ALTER ROLE tradehub_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE tradehub_user SET default_transaction_deferrable TO on;
ALTER ROLE tradehub_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE tradehub_db TO tradehub_user;
\q
```

### Step 6: Create Environment File

Create `/var/www/tradehub/.env`:

```bash
cat > /var/www/tradehub/.env << 'EOF'
DEBUG=False
SECRET_KEY=django-insecure-your-very-long-random-secret-key-here
ALLOWED_HOSTS=209.74.82.4,yourdomain.com,www.yourdomain.com

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=tradehub_db
DB_USER=tradehub_user
DB_PASSWORD=SecurePassword123!
DB_HOST=localhost
DB_PORT=5432

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
EOF
```

### Step 7: Update Django Settings

Create production settings file:

```bash
cat > /var/www/tradehub/tradehub/settings_production.py << 'EOF'
from .settings import *
import os

DEBUG = False
SECRET_KEY = os.environ.get('SECRET_KEY')
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

STATIC_URL = '/static/'
STATIC_ROOT = '/var/www/tradehub/staticfiles/'
MEDIA_ROOT = '/var/www/tradehub/media/'

SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
EOF
```

### Step 8: Run Django Setup

```bash
cd /var/www/tradehub
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production

# Create migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput
```

### Step 9: Setup Gunicorn Service

Create `/etc/systemd/system/tradehub.service`:

```bash
sudo cat > /etc/systemd/system/tradehub.service << 'EOF'
[Unit]
Description=TradeHub Django Gunicorn Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/var/www/tradehub
EnvironmentFile=/var/www/tradehub/.env
ExecStart=/var/www/tradehub/venv/bin/gunicorn \
    --workers 4 \
    --bind 127.0.0.1:8000 \
    --timeout 120 \
    --access-logfile /var/log/tradehub/access.log \
    --error-logfile /var/log/tradehub/error.log \
    tradehub.wsgi:application

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create log directory
sudo mkdir -p /var/log/tradehub
sudo chown www-data:www-data /var/log/tradehub
sudo chmod 755 /var/log/tradehub

# Set permissions
sudo chown -R www-data:www-data /var/www/tradehub
sudo chmod -R 755 /var/www/tradehub

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable tradehub
sudo systemctl start tradehub
```

### Step 10: Configure Nginx

Create `/etc/nginx/sites-available/tradehub`:

```bash
sudo cat > /etc/nginx/sites-available/tradehub << 'EOF'
server {
    listen 80;
    server_name 209.74.82.4 yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name 209.74.82.4 yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/209.74.82.4/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/209.74.82.4/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    location /static/ {
        alias /var/www/tradehub/staticfiles/;
        expires 30d;
    }

    location /media/ {
        alias /var/www/tradehub/media/;
        expires 7d;
    }
}
EOF

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/tradehub /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Step 11: Setup SSL Certificate

```bash
# For IP address
sudo certbot certonly --standalone -d 209.74.82.4 --non-interactive --agree-tos --email admin@example.com

# For domain (replace with your domain)
sudo certbot certonly --standalone -d yourdomain.com --non-interactive --agree-tos --email admin@example.com
```

### Step 12: Verify Deployment

```bash
# Check Gunicorn service
sudo systemctl status tradehub

# Check Nginx
sudo systemctl status nginx

# View logs
tail -f /var/log/tradehub/error.log
tail -f /var/log/tradehub/access.log

# Test application
curl http://127.0.0.1:8000
```

---

## 🌐 Access Your Application

Once deployed:

- **Main Website**: `https://209.74.82.4` or `https://yourdomain.com`
- **Admin Panel**: `https://209.74.82.4/admin` 
- **Admin Credentials**: (set during `createsuperuser` command)

---

## 📊 Useful Commands

### View Logs
```bash
# Gunicorn error log
tail -f /var/log/tradehub/error.log

# Gunicorn access log
tail -f /var/log/tradehub/access.log

# Nginx error log
tail -f /var/log/nginx/error.log

# Systemd journal
journalctl -u tradehub -f
```

### Restart Services
```bash
# Restart Gunicorn
sudo systemctl restart tradehub

# Restart Nginx
sudo systemctl restart nginx

# Restart both
sudo systemctl restart tradehub nginx
```

### Database Operations
```bash
cd /var/www/tradehub
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production

# Create backup
python manage.py dumpdata > backup.json

# Restore backup
python manage.py loaddata backup.json

# Access Django shell
python manage.py shell
```

### Static Files
```bash
cd /var/www/tradehub
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production

# Collect static files
python manage.py collectstatic --noinput

# Clear cache
python manage.py clear_cache
```

---

## 🔐 Security Checklist

- [ ] Change PostgreSQL password
- [ ] Generate new SECRET_KEY (use `python manage.py shell` → `from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())`)
- [ ] Update ALLOWED_HOSTS with your domain
- [ ] Enable HTTPS/SSL certificate
- [ ] Configure firewall (UFW)
- [ ] Setup automated backups
- [ ] Monitor disk space and logs
- [ ] Keep packages updated
- [ ] Setup uptime monitoring

### Setup Firewall (UFW)
```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22022/tcp  # SSH custom port if needed
```

---

## 🔄 Updating Application

When you have new code to deploy:

```bash
cd /var/www/tradehub
source venv/bin/activate

# Pull latest code
git pull origin main

# Install any new dependencies
pip install -r requirements.txt

# Run migrations
export DJANGO_SETTINGS_MODULE=tradehub.settings_production
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Restart service
sudo systemctl restart tradehub
```

---

## 🛠️ Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status tradehub

# Check logs
journalctl -u tradehub -n 50

# Check permissions
ls -la /var/www/tradehub
```

### Static Files Not Loading
```bash
# Recollect static files
cd /var/www/tradehub
source venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart nginx
```

### Database Connection Error
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check database exists
sudo -u postgres psql -l

# Test connection
psql -U tradehub_user -d tradehub_db -h localhost
```

### Port Already in Use
```bash
# Find process using port 8000
sudo lsof -i :8000

# Kill process
sudo kill -9 <PID>
```

---

## 📞 Support & Resources

- Django Deployment: https://docs.djangoproject.com/en/5.2/howto/deployment/
- Gunicorn: https://gunicorn.org/
- Nginx: https://nginx.org/
- PostgreSQL: https://www.postgresql.org/docs/

---

**Last Updated**: December 5, 2025
