# TradeHub Deployment Checklist

## Pre-Deployment Checklist

- [ ] Read README_DEPLOYMENT.md (5 min)
- [ ] Read DEPLOYMENT_SETUP.md (10 min)
- [ ] Verify VPS access: ssh -p 22022 root@209.74.82.4
- [ ] Test SSH password: @Akm12109
- [ ] Have internet connection available
- [ ] VPS has 2GB+ RAM, 20GB+ disk space
- [ ] Optional: Prepare domain name for later

## Deployment Steps

### Step 1: SSH into VPS
- [ ] Open terminal on your computer
- [ ] Run: `ssh -p 22022 root@209.74.82.4`
- [ ] Enter password: `@Akm12109`
- [ ] Verify you're logged in (see `root@` prompt)

### Step 2: Clone Project
- [ ] In VPS terminal, run:
```bash
cd /tmp
git clone https://github.com/Sandeepbhiwani/tradehub tradehub-setup
cd tradehub-setup
```
- [ ] Verify clone completed

### Step 3: Make Script Executable
- [ ] Run: `chmod +x deploy.sh`
- [ ] Verify: `ls -la deploy.sh` (should show -rwx)

### Step 4: Run Deployment
- [ ] Run: `sudo ./deploy.sh`
- [ ] **WAIT 5-10 minutes** for completion
- [ ] Watch for error messages
- [ ] Note any important information shown at the end

### Step 5: Verify Deployment
- [ ] Check service status: `sudo systemctl status tradehub`
- [ ] Check Nginx: `sudo systemctl status nginx`
- [ ] Check PostgreSQL: `sudo systemctl status postgresql`

## Post-Deployment Checklist

### Access Application
- [ ] Open browser
- [ ] Visit: `https://209.74.82.4/admin`
- [ ] Accept SSL warning (self-signed or Let's Encrypt)
- [ ] Verify admin login page loads
- [ ] Login with admin credentials (set during deployment)
- [ ] Verify admin dashboard loads

### Test Features
- [ ] Access main website: `https://209.74.82.4/`
- [ ] Check if pages load correctly
- [ ] Test a few features
- [ ] No errors in browser console

### Check Logs
- [ ] SSH into VPS again: `ssh -p 22022 root@209.74.82.4`
- [ ] View error logs: `tail -f /var/log/tradehub/error.log`
- [ ] Verify no critical errors
- [ ] Exit with Ctrl+C

## Security Configuration (DO IMMEDIATELY)

### 1. Change Django Secret Key
- [ ] In VPS terminal, run:
```bash
cd /var/www/tradehub && source venv/bin/activate
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```
- [ ] Copy the generated key
- [ ] Edit .env: `nano /var/www/tradehub/.env`
- [ ] Find: `SECRET_KEY=`
- [ ] Replace value with copied key
- [ ] Save (Ctrl+O, Enter, Ctrl+X)
- [ ] Restart app: `sudo systemctl restart tradehub`

### 2. Update ALLOWED_HOSTS
- [ ] Edit .env: `nano /var/www/tradehub/.env`
- [ ] Find: `ALLOWED_HOSTS=`
- [ ] Update with your domain/IP
- [ ] Example: `ALLOWED_HOSTS=209.74.82.4,yourdomain.com,www.yourdomain.com`
- [ ] Save and exit
- [ ] Restart app: `sudo systemctl restart tradehub`

### 3. Change Database Password (Optional but Recommended)
- [ ] In VPS terminal as root
- [ ] Connect to PostgreSQL: `sudo -u postgres psql`
- [ ] Run: `ALTER USER tradehub_user WITH PASSWORD 'NewSecurePassword123!';`
- [ ] Type: `\q` to exit
- [ ] Update .env with new password
- [ ] Restart app: `sudo systemctl restart tradehub`

### 4. Configure Email (Optional)
- [ ] Edit .env: `nano /var/www/tradehub/.env`
- [ ] Fill in EMAIL_HOST_USER and EMAIL_HOST_PASSWORD
- [ ] Save and exit
- [ ] Restart app: `sudo systemctl restart tradehub`

### 5. Enable Firewall (Recommended)
- [ ] In VPS terminal, run:
```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
```

## Ongoing Management

### Daily/Weekly Tasks
- [ ] Check logs for errors: `tail -f /var/log/tradehub/error.log`
- [ ] Monitor disk space: `df -h`
- [ ] Check system resources: `top` (Ctrl+C to exit)
- [ ] Verify application is running: `sudo systemctl status tradehub`

### Monthly Tasks
- [ ] Backup database (see QUICK_REFERENCE.md)
- [ ] Review security settings
- [ ] Check for updates: `apt list --upgradable`

### As Needed
- [ ] Update application: Follow QUICK_REFERENCE.md → Update Application
- [ ] Restart services: `sudo systemctl restart tradehub nginx postgresql`
- [ ] View logs: `tail -f /var/log/tradehub/error.log`
- [ ] Access Django shell: Follow QUICK_REFERENCE.md

## Helpful Commands

### Quick Status Check
```bash
sudo systemctl status tradehub
sudo systemctl status nginx
sudo systemctl status postgresql
```

### View Logs
```bash
# Error logs
tail -f /var/log/tradehub/error.log

# Access logs
tail -f /var/log/tradehub/access.log

# Last 20 lines
tail -20 /var/log/tradehub/error.log
```

### Restart Services
```bash
sudo systemctl restart tradehub
sudo systemctl restart nginx
sudo systemctl restart postgresql

# Restart all
sudo systemctl restart tradehub nginx postgresql
```

### Access Management Menu
```bash
sudo /var/www/tradehub/manage_app.sh
```

## Troubleshooting

### Application won't start
1. Check status: `sudo systemctl status tradehub`
2. View logs: `tail -50 /var/log/tradehub/error.log`
3. Restart: `sudo systemctl restart tradehub`
4. Check again: `sudo systemctl status tradehub`

### Can't connect to database
1. Check PostgreSQL: `sudo systemctl status postgresql`
2. Restart: `sudo systemctl restart postgresql`
3. Check .env password is correct
4. Restart app: `sudo systemctl restart tradehub`

### Static files not loading
1. Collect static files: `cd /var/www/tradehub && source venv/bin/activate && python manage.py collectstatic --noinput`
2. Restart Nginx: `sudo systemctl restart nginx`

### Port already in use
1. Find process: `sudo lsof -i :8000` or `sudo lsof -i :80`
2. Kill process: `sudo kill -9 <PID>`
3. Restart service: `sudo systemctl restart tradehub` or `sudo systemctl restart nginx`

## Important Files Reference

| Path | Purpose |
|------|---------|
| `/var/www/tradehub/` | Application root |
| `/var/www/tradehub/.env` | Configuration (secrets) |
| `/var/log/tradehub/` | Logs directory |
| `/etc/systemd/system/tradehub.service` | Service definition |
| `/etc/nginx/sites-available/tradehub` | Nginx config |
| `/var/www/tradehub/media/` | User uploads |
| `/var/www/tradehub/staticfiles/` | Static files |

## Contact & Support

- **Documentation**: Check README_DEPLOYMENT.md
- **Quick Commands**: See QUICK_REFERENCE.md
- **Detailed Help**: See VPS_DEPLOYMENT_GUIDE.md
- **File Info**: See FILE_MANIFEST.txt

---

**Deployment Date**: ________________
**Deployed By**: ________________
**Admin Password**: ________________ (Store safely!)
**Domain/IP**: ________________

---

Print this checklist and check off items as you complete them!

Created: December 5, 2025
