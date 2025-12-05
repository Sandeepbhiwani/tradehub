#!/bin/bash

# TradeHub Django - VPS Production Deployment Script
# For Ubuntu 24.04 LTS on 209.74.82.4
# Run this script as root or with sudo

set -e

echo "════════════════════════════════════════════════════════════"
echo "  TradeHub Django - Production Deployment Setup"
echo "════════════════════════════════════════════════════════════"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="tradehub"
PROJECT_DIR="/var/www/tradehub"
DOMAIN="209.74.82.4"  # Change this to your domain
APP_USER="www-data"
PYTHON_VERSION="python3"

echo -e "\n${YELLOW}Step 1: System Updates${NC}"
apt-get update
apt-get upgrade -y
apt-get install -y python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib postgresql-common \
    nginx supervisor curl wget git \
    build-essential libpq-dev \
    ssl-cert certbot python3-certbot-nginx

echo -e "\n${YELLOW}Step 2: Create Project Directory${NC}"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

echo -e "\n${YELLOW}Step 3: Clone or Copy Project${NC}"
# Option A: Clone from Git (uncomment if using Git)
# git clone https://github.com/Sandeepbhiwani/tradehub .

# Option B: Copy from existing location
# scp -r /path/to/local/tradehub/* root@209.74.82.4:$PROJECT_DIR/

echo "Repository should be at: $PROJECT_DIR"
ls -la

echo -e "\n${YELLOW}Step 4: Create Virtual Environment${NC}"
$PYTHON_VERSION -m venv venv
source venv/bin/activate

echo -e "\n${YELLOW}Step 5: Install Python Dependencies${NC}"
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "\n${YELLOW}Step 6: Setup PostgreSQL Database${NC}"
sudo -u postgres psql << EOF
CREATE DATABASE tradehub_db;
CREATE USER tradehub_user WITH PASSWORD 'ChangeMe@123SecurePassword';
ALTER ROLE tradehub_user SET client_encoding TO 'utf8';
ALTER ROLE tradehub_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE tradehub_user SET default_transaction_deferrable TO on;
ALTER ROLE tradehub_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE tradehub_db TO tradehub_user;
EOF

echo -e "\n${YELLOW}Step 7: Create .env File for Production${NC}"
cat > $PROJECT_DIR/.env << 'EOF'
# Django Settings
DEBUG=False
SECRET_KEY=your-secret-key-here-change-this-in-production
ALLOWED_HOSTS=209.74.82.4,www.yourdomain.com,yourdomain.com

# Database Configuration
DB_ENGINE=django.db.backends.postgresql
DB_NAME=tradehub_db
DB_USER=tradehub_user
DB_PASSWORD=ChangeMe@123SecurePassword
DB_HOST=localhost
DB_PORT=5432

# Email Configuration (Optional)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
EOF

echo -e "\n${YELLOW}Step 8: Update Django Settings for Production${NC}"
# Create a production settings module
cat > $PROJECT_DIR/tradehub/settings_production.py << 'EOF'
from .settings import *
import os
from django.core.management.utils import get_random_secret_key

# Override with environment variables
DEBUG = False
SECRET_KEY = os.environ.get('SECRET_KEY', get_random_secret_key())
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Database Configuration
DATABASES = {
    'default': {
        'ENGINE': os.environ.get('DB_ENGINE', 'django.db.backends.postgresql'),
        'NAME': os.environ.get('DB_NAME', 'tradehub_db'),
        'USER': os.environ.get('DB_USER', 'tradehub_user'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

# Security Settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_SECURITY_POLICY = {
    'default-src': ("'self'",),
}

# Static Files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles/')

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media/')

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': '/var/log/tradehub/django.log',
        },
    },
    'root': {
        'handlers': ['file'],
        'level': 'WARNING',
    },
}
EOF

echo -e "\n${YELLOW}Step 9: Run Django Migrations${NC}"
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production
python manage.py migrate
python manage.py createsuperuser --noinput --username admin --email admin@example.com || true
python manage.py collectstatic --noinput

echo -e "\n${YELLOW}Step 10: Set File Permissions${NC}"
chown -R $APP_USER:$APP_USER $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
chmod -R 775 $PROJECT_DIR/media
chmod -R 775 $PROJECT_DIR/staticfiles

echo -e "\n${YELLOW}Step 11: Create Gunicorn Service${NC}"
cat > /etc/systemd/system/tradehub.service << EOF
[Unit]
Description=TradeHub Django Gunicorn Application
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=notify
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$PROJECT_DIR
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=$PROJECT_DIR/venv/bin/gunicorn \\
    --workers 4 \\
    --worker-class sync \\
    --bind 127.0.0.1:8000 \\
    --timeout 120 \\
    --access-logfile /var/log/tradehub/access.log \\
    --error-logfile /var/log/tradehub/error.log \\
    --log-level info \\
    tradehub.wsgi:application

Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tradehub
systemctl start tradehub

echo -e "\n${YELLOW}Step 12: Configure Nginx${NC}"
cat > /etc/nginx/sites-available/tradehub << EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL Certificates (update with your cert paths)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /static/ {
        alias $PROJECT_DIR/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias $PROJECT_DIR/media/;
        expires 7d;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

# Enable Nginx site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/tradehub /etc/nginx/sites-enabled/tradehub

# Test Nginx configuration
nginx -t

echo -e "\n${YELLOW}Step 13: Setup SSL Certificate with Let's Encrypt${NC}"
# Change domain to your actual domain
certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email admin@example.com || true

echo -e "\n${YELLOW}Step 14: Create Log Directory${NC}"
mkdir -p /var/log/tradehub
chown $APP_USER:$APP_USER /var/log/tradehub
chmod 755 /var/log/tradehub

echo -e "\n${YELLOW}Step 15: Start Services${NC}"
systemctl restart nginx
systemctl restart tradehub

echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}\n"

echo "Access your application at:"
echo -e "${YELLOW}https://$DOMAIN${NC}\n"

echo "Admin Panel:"
echo -e "${YELLOW}https://$DOMAIN/admin/${NC}\n"

echo "Useful Commands:"
echo "  View logs:              tail -f /var/log/tradehub/error.log"
echo "  Restart service:        systemctl restart tradehub"
echo "  Check service status:   systemctl status tradehub"
echo "  Django shell:           cd $PROJECT_DIR && source venv/bin/activate && python manage.py shell"
echo "  Collect static:         cd $PROJECT_DIR && source venv/bin/activate && python manage.py collectstatic"
echo ""
echo -e "${YELLOW}Important: Don't forget to:${NC}"
echo "  1. Update the SECRET_KEY in .env file"
echo "  2. Update ALLOWED_HOSTS in .env with your domain"
echo "  3. Configure database password securely"
echo "  4. Setup email configuration"
echo "  5. Renew SSL certificate: certbot renew --dry-run"
echo ""
