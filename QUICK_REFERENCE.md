# TradeHub VPS Deployment - Quick Reference

## 🚀 One-Command Deployment

```bash
ssh -p 22022 root@209.74.82.4
cd /tmp && git clone https://github.com/Sandeepbhiwani/tradehub tradehub-setup && cd tradehub-setup && chmod +x deploy.sh && sudo ./deploy.sh
```

---

## 📝 Manual Deployment Checklist

### Prerequisites
- [ ] SSH access to VPS
- [ ] Root/sudo privileges
- [ ] Git repository access
- [ ] Domain name (optional)

### Installation
- [ ] Update system packages
- [ ] Install Python 3, PostgreSQL, Nginx
- [ ] Clone/copy project files
- [ ] Create virtual environment
- [ ] Install Python dependencies

### Database Setup
- [ ] Create PostgreSQL database
- [ ] Create database user
- [ ] Set proper permissions
- [ ] Test connection

### Django Configuration
- [ ] Create .env file with secrets
- [ ] Update ALLOWED_HOSTS
- [ ] Run migrations
- [ ] Create superuser
- [ ] Collect static files

### Service Configuration
- [ ] Create Gunicorn service file
- [ ] Create Nginx configuration
- [ ] Enable and start services
- [ ] Test application

### Security & SSL
- [ ] Install SSL certificate (Let's Encrypt)
- [ ] Configure HTTPS redirect
- [ ] Enable firewall (UFW)
- [ ] Allow required ports

### Verification
- [ ] Access website
- [ ] Login to admin panel
- [ ] Check logs for errors
- [ ] Test all features

---

## 🌐 Access Points After Deployment

| Service | URL | Notes |
|---------|-----|-------|
| Website | `https://209.74.82.4` | Or your domain |
| Admin | `https://209.74.82.4/admin` | Login required |
| Static Files | `https://209.74.82.4/static/` | CSS, JS, images |
| Media | `https://209.74.82.4/media/` | User uploads |

---

## 📂 Important Directories

```
/var/www/tradehub/                 # Project root
├── .env                           # Environment variables (SECRET)
├── manage.py                      # Django management
├── requirements.txt               # Python dependencies
├── venv/                          # Virtual environment
├── tradehub/                      # Main Django app
├── staticfiles/                   # Collected static files
├── media/                         # User uploads
└── db.sqlite3                     # SQLite (if using)
```

---

## 🔧 Common Tasks

### Restart Application
```bash
sudo systemctl restart tradehub
```

### Check Status
```bash
sudo systemctl status tradehub
sudo systemctl status nginx
sudo systemctl status postgresql
```

### View Logs
```bash
tail -f /var/log/tradehub/error.log
tail -f /var/log/tradehub/access.log
journalctl -u tradehub -f
```

### Backup Database
```bash
cd /var/www/tradehub
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production
python manage.py dumpdata > backup_$(date +%Y%m%d_%H%M%S).json
```

### Update Application
```bash
cd /var/www/tradehub
git pull origin main
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart tradehub
```

---

## 🔐 Security Quick Checklist

```bash
# Change SECRET_KEY
# Edit /var/www/tradehub/.env and generate new key:
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# Enable Firewall
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check File Permissions
ls -la /var/www/tradehub/.env

# Enable Auto-Updates
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 🆘 Emergency Commands

### If Service Crashes
```bash
sudo systemctl restart tradehub
sudo systemctl restart nginx
sudo systemctl status tradehub
```

### If Database Connection Fails
```bash
sudo systemctl restart postgresql
sudo -u postgres psql -c "SELECT 1;"
```

### Clear Error Logs
```bash
truncate -s 0 /var/log/tradehub/error.log
truncate -s 0 /var/log/tradehub/access.log
```

### Full System Reset
```bash
cd /var/www/tradehub
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production

# Reset database
python manage.py flush --noinput

# Fresh migrations
python manage.py migrate

# Create new superuser
python manage.py createsuperuser

# Collect static
python manage.py collectstatic --noinput

# Restart
sudo systemctl restart tradehub
```

---

## 📊 System Resources

Check resource usage:
```bash
# Memory usage
free -h

# Disk usage
df -h

# CPU usage
top
ps aux | grep python

# Network connections
netstat -tulpn | grep 8000
```

---

## 📞 Quick Support

- SSH: `ssh -p 22022 root@209.74.82.4`
- Database: PostgreSQL on localhost:5432
- App Server: Gunicorn on 127.0.0.1:8000
- Web Server: Nginx on 0.0.0.0:80/443

---

## ⚡ Performance Tips

1. **Enable caching**: Configure Redis
2. **Optimize database**: Add indexes for frequently queried fields
3. **Gzip compression**: Already enabled in Nginx
4. **CDN**: Serve static files via CDN
5. **Monitor**: Setup New Relic or similar

---

**Created**: December 5, 2025
**Project**: TradeHub Django Application
**VPS IP**: 209.74.82.4
