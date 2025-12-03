# Django 5.2 was used to generate migrations; use 5.2.x series
Django>=5.2,<6.0

# Forms and styles
django-crispy-forms>=2.0
# crispy-tailwind 2.x is not available – use the latest 1.x series that works with this project
crispy-tailwind>=1.0.3,<2.0

# HTTP calls
requests>=2.30.0

# Production / Hosting
gunicorn>=20.1.0
whitenoise>=6.0
psycopg2-binary>=2.9

# Environment and DB helpers
dj-database-url>=1.0.0
django-environ>=0.9.0

# Optional: Django AllAuth
django-allauth>=1.8.0

# Dev tools (optional)
coverage>=6.5.0
pytest>=7.0.0
qrcode[pil]
