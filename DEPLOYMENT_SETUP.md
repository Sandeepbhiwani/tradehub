# 🚀 TradeHub Production Deployment - Complete Setup

## 📦 What's Included

Your TradeHub Django project now has complete production deployment documentation and tools:

### 📄 Documentation Files

1. **`VPS_DEPLOYMENT_GUIDE.md`** - Complete step-by-step deployment guide
   - Automated one-click deployment
   - Manual step-by-step instructions
   - Security checklist
   - Troubleshooting guide

2. **`QUICK_REFERENCE.md`** - Quick commands and checklist
   - One-liner commands
   - Common tasks
   - Emergency procedures
   - System monitoring

3. **`.env.example`** - Environment variables template
   - All required environment variables
   - Configuration options
   - Security settings
   - Third-party integrations

4. **`HOSTING_GUIDE.md`** - Local development and basic hosting
   - Local setup instructions
   - Development server info
   - Production checklist

### 🛠️ Automation Scripts

1. **`deploy.sh`** - Automated deployment script
   - One-command setup
   - Installs all dependencies
   - Configures services
   - Sets up SSL/HTTPS
   - Creates systemd services

2. **`manage_app.sh`** - Application management utility
   - Start/stop/restart application
   - View logs in real-time
   - Backup/restore database
   - Update application
   - Monitor system resources
   - Django shell access

---

## 🚀 Quick Start Deployment

### Method 1: One-Click (Fastest)

```bash
# SSH into VPS
ssh -p 22022 root@209.74.82.4

# Run this one command:
cd /tmp && git clone https://github.com/Sandeepbhiwani/tradehub tradehub-setup && \
cd tradehub-setup && chmod +x deploy.sh && sudo ./deploy.sh
```

**That's it!** Your application will be live in ~10 minutes.

### Method 2: Manual (Step-by-Step)

Follow the detailed instructions in `VPS_DEPLOYMENT_GUIDE.md`

### Method 3: Copy and Adapt

1. Use `deploy.sh` as a template for your specific requirements
2. Modify paths, ports, domains as needed
3. Run step-by-step with error checking

---

## 📊 What Gets Installed

The automated script (`deploy.sh`) will:

✅ **System Setup**
- Update system packages
- Install Python 3, pip, venv
- Install PostgreSQL database
- Install Nginx web server
- Install SSL certificate support

✅ **Python Environment**
- Create virtual environment
- Install all pip dependencies
- Setup production database backend

✅ **Database**
- Create PostgreSQL database
- Create database user with permissions
- Test connection

✅ **Django Configuration**
- Create `.env` file with settings
- Configure production settings
- Run migrations
- Collect static files
- Create superuser (admin account)

✅ **Application Server**
- Setup Gunicorn WSGI server
- Create systemd service for auto-restart
- Configure logging

✅ **Web Server**
- Configure Nginx reverse proxy
- Setup SSL/HTTPS with Let's Encrypt
- Configure security headers
- Enable caching

✅ **Security**
- Firewall rules
- SSL certificates
- Security headers
- Secure cookie settings

---

## 🌐 After Deployment

### Access Your Application

| Component | URL | Purpose |
|-----------|-----|---------|
| Website | `https://209.74.82.4` | Main application |
| Admin Panel | `https://209.74.82.4/admin` | Django admin |
| API (if any) | `https://209.74.82.4/api/` | REST endpoints |

### Default Credentials

- **Admin Username**: `admin` (or your choice during setup)
- **Admin Password**: Set during `createsuperuser` step

### Important Files

```
/var/www/tradehub/
├── .env                          # ⚠️ SECRETS - Keep safe!
├── db.sqlite3                    # SQLite (if using)
├── venv/                         # Virtual environment
├── staticfiles/                  # Collected static files
├── media/                        # User uploads
├── manage.py                     # Django management
└── manage_app.sh                 # Application management script
```

### Logs & Monitoring

```bash
# View application logs
tail -f /var/log/tradehub/error.log

# View access logs
tail -f /var/log/tradehub/access.log

# Check service status
sudo systemctl status tradehub

# Monitor resources
top
df -h
free -h
```

---

## 🔧 Management Commands

Once deployed, use the management script for common tasks:

```bash
# Make script executable
chmod +x /var/www/tradehub/manage_app.sh

# Run management menu
sudo /var/www/tradehub/manage_app.sh
```

**Available commands:**
- Start/stop/restart application
- View logs in real-time
- Backup/restore database
- Update application code
- Check system resources
- Access Django shell
- Reset database
- Restart services

---

## 🔐 Security Checklist

After deployment, complete these tasks:

- [ ] Change SECRET_KEY in `.env`
- [ ] Update ALLOWED_HOSTS with your domain
- [ ] Change PostgreSQL password
- [ ] Create strong superuser password
- [ ] Configure email settings
- [ ] Enable two-factor authentication (optional)
- [ ] Setup automated backups
- [ ] Monitor logs regularly
- [ ] Keep packages updated

### Generate New SECRET_KEY

```bash
ssh -p 22022 root@209.74.82.4
cd /var/www/tradehub
source venv/bin/activate
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Copy the output and update `.env`:

```bash
nano /var/www/tradehub/.env
# Update SECRET_KEY=<paste_new_key>
```

---

## 🔄 Updating Your Application

To update with new code:

```bash
# Option 1: Using management script
sudo /var/www/tradehub/manage_app.sh
# Select option 5: Update application

# Option 2: Manual
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

## 📞 Deployment Information

| Item | Details |
|------|---------|
| **VPS IP** | 209.74.82.4 |
| **SSH Port** | 22022 |
| **Root User** | root |
| **App Directory** | /var/www/tradehub |
| **App User** | www-data |
| **Database** | PostgreSQL |
| **Web Server** | Nginx |
| **App Server** | Gunicorn |
| **Python Version** | 3.12 (Ubuntu 24.04) |

---

## 🆘 Troubleshooting

### Application Won't Start

```bash
# Check service status
sudo systemctl status tradehub

# View logs
sudo journalctl -u tradehub -n 50

# Check permissions
ls -la /var/www/tradehub/.env

# Restart
sudo systemctl restart tradehub
```

### Static Files Not Loading

```bash
cd /var/www/tradehub
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=tradehub.settings_production
python manage.py collectstatic --noinput
sudo systemctl restart nginx
```

### Database Connection Error

```bash
# Check PostgreSQL
sudo systemctl status postgresql

# Test connection
psql -U tradehub_user -d tradehub_db -h localhost

# View database
sudo -u postgres psql -l
```

### Port 80/443 Already in Use

```bash
# Check what's using the port
sudo lsof -i :80
sudo lsof -i :443

# Kill process
sudo kill -9 <PID>

# Restart Nginx
sudo systemctl restart nginx
```

---

## 📚 Additional Resources

- **Django Documentation**: https://docs.djangoproject.com/
- **Gunicorn**: https://gunicorn.org/
- **Nginx**: https://nginx.org/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Let's Encrypt**: https://letsencrypt.org/
- **Ubuntu Server Guide**: https://ubuntu.com/server/docs

---

## 💡 Tips for Production

1. **Regular Backups**: Set up automated database backups
2. **Monitor Logs**: Check logs regularly for errors
3. **Update Regularly**: Keep system and packages updated
4. **Monitor Resources**: Watch disk space and memory usage
5. **Use Monitoring**: Setup New Relic, DataDog, or similar
6. **Optimize Database**: Add indexes for frequently queried fields
7. **Enable Caching**: Configure Redis for better performance
8. **CDN**: Serve static files via CDN for better performance

---

## 🎯 Next Steps

1. ✅ Deploy using `deploy.sh`
2. ✅ Verify application is running
3. ✅ Update security settings (.env file)
4. ✅ Configure domain (if using custom domain)
5. ✅ Setup automated backups
6. ✅ Configure email settings
7. ✅ Setup monitoring/uptime alerts
8. ✅ Test all features thoroughly

---

## 📝 Production Deployment Checklist

- [ ] Deploy application with `deploy.sh`
- [ ] Verify application starts successfully
- [ ] Access admin panel and login
- [ ] Change SECRET_KEY in .env
- [ ] Update ALLOWED_HOSTS
- [ ] Configure database password
- [ ] Setup email configuration
- [ ] Test all major features
- [ ] Setup automated backups
- [ ] Configure monitoring
- [ ] Optimize database
- [ ] Enable caching (optional)
- [ ] Setup CDN (optional)
- [ ] Document your deployment
- [ ] Create deployment runbook

---

**Created**: December 5, 2025  
**Project**: TradeHub Django Application  
**Status**: ✅ Ready for Production Deployment  

For questions or issues, refer to the detailed guides included with your project.
