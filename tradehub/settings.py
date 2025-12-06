import os
from pathlib import Path
import dj_database_url   # added

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-zaea+i*&noml4wqe+l1!5=axtm_gxurd*hz8jku&u6qw$x=4jk'

DEBUG = True

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    'crispy_forms',
    'crispy_tailwind',
    'accounts',
    'dashboard',
    'payments',
    'stockmanagement',
    'assets'
]

AUTH_USER_MODEL = 'accounts.CustomUser'

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'tradehub.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join('templates')],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'dashboard.context_processors.site_settings_context',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'tradehub.wsgi.application'

# ---------------------------
# 🔥 NEON POSTGRESQL DATABASE
# ---------------------------

DATABASES = {
    'default': dj_database_url.parse(
        "postgresql://neondb_owner:npg_4o8hXjirHWpN@ep-sparkling-bird-ahc14igj-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require",
        conn_max_age=600,
        ssl_require=True
    )
}

# ---------------------------

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]

LOGIN_URL = 'login'
LOGIN_REDIRECT_URL = 'dashboard'
LOGOUT_URL = 'logout'
LOGOUT_REDIRECT_URL = 'login'

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
