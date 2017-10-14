import environ
import raven


# --- BASE ---
root = environ.Path(__file__)
env = environ.Env()

BASE_DIR = root()

DEBUG = env('DEBUG', default=False)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])
SITE_ID = env('SITE_ID', default=1)
SECRET_KEY = env('SECRET_KEY')
WSGI_APPLICATION = 'config.wsgi.application'
ROOT_URLCONF = 'config.urls'

INSTALLED_APPS = [
    'jet.dashboard',
    'jet',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django_extensions',
    'rest_framework',
    'rest_framework.authtoken',
    # 'social_django',
    'djoser',
    'stdimage',
    'django_cleanup',
    'taggit',
    'taggit_serializer',
    'django_filters',
    'corsheaders',
    'raven.contrib.django.raven_compat',
    'cachalot',

    'gifz_api.accounts',
    'gifz_api.gifs',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# --- DB ---
DATABASES = {
    'default': env.db(
        default='postgres://postgres:postgres@postgres:5432/postgres',
    ),
}

# --- AUTH ---
AUTH_USER_MODEL = 'accounts.User'
# SOCIAL_AUTH_USER_MODEL = 'accounts.User'

# AUTHENTICATION_BACKENDS = (
#     'gifz_api.lib.djoser.social.backends.google_openidconnect.GoogleOpenIdConnect',  # noqa: E501
#     'django.contrib.auth.backends.ModelBackend',
# )
# SOCIAL_AUTH_AUTHENTICATION_BACKENDS = (
#     'gifz_api.lib.djoser.social.backends.google_openidconnect.GoogleOpenIdConnect',  # noqa: E501
# )
# SOCIAL_AUTH_GOOGLE_OPENIDCONNECT_KEY = env(
#     'GOOGLE_OAUTH2_KEY',
# )
# SOCIAL_AUTH_GOOGLE_OPENIDCONNECT_SECRET = env(
#     'GOOGLE_OAUTH2_SECRET',
# )
# SOCIAL_AUTH_POSTGRES_JSONFIELD = True

# DJOSER = {
#     'SOCIAL_AUTH_ALLOWED_REDIRECT_URIS': [
#         'http://localhost:8000',
#     ],
# }

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',  # noqa: E501
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',  # noqa: E501
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',  # noqa: E501
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',  # noqa: E501
    },
]

# --- TEMPLATES ---
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# --- I18N ---
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_L10N = True
USE_TZ = True

# --- FILES ---
STATIC_URL = env('STATIC_URL', default='/static/')
STATIC_ROOT = env('STATIC_ROOT', default=(root - 3)('static'))
MEDIA_URL = env('MEDIA_URL', default='/media/')
MEDIA_ROOT = env('MEDIA_ROOT', default=(root - 3)('media'))

# --- REST FRAMEWORK ---
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ),
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.TokenAuthentication',
    ),
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
    ),
    'DEFAULT_VERSIONING_CLASS': 'rest_framework.versioning.NamespaceVersioning',  # noqa: E501
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.LimitOffsetPagination',  # noqa: E501
    'PAGE_SIZE': 25,
}

# --- CACHE ---
CACHES = {
    'default': env.cache(
        default='redis://redis:6379/1?client_class=django_redis.client.DefaultClient',  # noqa: E501
    ),
}
CACHALOT_ENABLED = env.bool('CACHALOT_ENABLED', default=False)
CACHALOT_TIMEOUT = env('CACHALOT_TIMEOUT', default=60*20)

# --- SENTRY ---
RAVEN_DSN = env('RAVEN_DSN', default=None)
if RAVEN_DSN:
    RAVEN_CONFIG = {
        'dsn': env('RAVEN_DSN'),
        'release': raven.fetch_git_sha((root - 2)()),
    }

# --- CORS ---
CORS_ORIGIN_WHITELIST = env.list('CORS_ORIGIN_WHITELIST', default=[])

# --- DEBUG MODE ---
if DEBUG:
    INSTALLED_APPS += [
        'debug_toolbar',
    ]
    MIDDLEWARE += [
        'debug_toolbar.middleware.DebugToolbarMiddleware',
    ]

    REST_FRAMEWORK['DEFAULT_AUTHENTICATION_CLASSES'] = (
        *REST_FRAMEWORK['DEFAULT_AUTHENTICATION_CLASSES'],  # type: ignore
        'rest_framework.authentication.SessionAuthentication',
    )

    DEBUG_TOOLBAR_CONFIG = {
        'SHOW_TOOLBAR_CALLBACK': lambda request: True,
    }

# --- APPLICATION ---
GIFS_PAGE_SIZE = env('GIFS_PAGE_SIZE', default=40)