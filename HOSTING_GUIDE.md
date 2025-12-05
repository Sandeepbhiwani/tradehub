# TradeHub Django Project - Hosting Guide

## ✅ Local Setup Complete!

The TradeHub Django project has been successfully set up and is now running locally.

### Current Status
- **Server Running**: ✅ YES
- **Port**: 8000
- **Database**: SQLite3
- **Admin User**: admin

### Access the Application

1. **Main Application**: http://localhost:8000/
2. **Django Admin**: http://localhost:8000/admin/
   - Username: `admin`
   - Password: (set during setup - you'll need to create one or reset it)

### Project Structure
```
tradehub/
├── accounts/          # User authentication & profiles
├── assets/            # Asset management
├── dashboard/         # Main dashboard
├── payments/          # Payment processing
├── stockmanagement/   # Stock management
├── home/              # Home page
├── templates/         # HTML templates
├── tradehub/          # Project settings
├── manage.py          # Django management
└── venv/              # Virtual environment
```

### Important Files
- `requirements.txt` - All Python dependencies
- `tradehub/settings.py` - Project configuration
- `db.sqlite3` - SQLite database (created during migration)

### For Production Deployment on VPS

When deploying to your VPS (209.74.82.4), use **Gunicorn** with **Nginx**:

#### Step 1: Install Dependencies on VPS
```bash
# SSH into VPS
ssh -p 22022 root@209.74.82.4

# Create project directory
mkdir -p /var/www/tradehub
cd /var/www/tradehub

# Clone or copy the project
git clone <your-repo-url> .
# OR copy files directly

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### Step 2: Configure Django for Production
```bash
# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput
```

#### Step 3: Start Gunicorn
```bash
# Run with Gunicorn
gunicorn --bind 0.0.0.0:8000 \
         --workers 4 \
         --timeout 120 \
         --access-logfile - \
         --error-logfile - \
         tradehub.wsgi:application
```

#### Step 4: Configure Nginx (Reverse Proxy)
Create `/etc/nginx/sites-available/tradehub`:
```nginx
server {
    listen 80;
    server_name 209.74.82.4;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /var/www/tradehub/staticfiles/;
    }

    location /media/ {
        alias /var/www/tradehub/media/;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/tradehub /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Step 5: Use Systemd Service (Optional but Recommended)
Create `/etc/systemd/system/tradehub.service`:
```ini
[Unit]
Description=TradeHub Django Application
After=network.target

[Service]
Type=notify
User=www-data
WorkingDirectory=/var/www/tradehub
ExecStart=/var/www/tradehub/venv/bin/gunicorn \
          --bind 127.0.0.1:8000 \
          --workers 4 \
          tradehub.wsgi:application
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl start tradehub
sudo systemctl enable tradehub
```

### Important Security Notes for Production
1. Change `DEBUG = False` in settings.py
2. Generate a new `SECRET_KEY`
3. Update `ALLOWED_HOSTS` with your domain
4. Use environment variables for sensitive data (.env file)
5. Configure HTTPS with SSL certificate (Let's Encrypt)
6. Set up proper database (PostgreSQL recommended instead of SQLite)

### Troubleshooting
- **Static files not loading**: Run `python manage.py collectstatic`
- **Database errors**: Ensure migrations are applied: `python manage.py migrate`
- **Permission issues on VPS**: Check file ownership: `sudo chown -R www-data:www-data /var/www/tradehub`

### Next Steps
1. Test all features locally
2. Update settings for production
3. Deploy to VPS using the guide above
4. Monitor application logs

---
Generated: December 5, 2025
