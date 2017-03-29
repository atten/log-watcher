import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
STATIC_ROOT = os.path.join(BASE_DIR, 'static')

AUTH_FILE = os.path.join(BASE_DIR, 'data', 'auth')
COMPILED_JS_URLS_FILE = os.path.join(STATIC_ROOT, 'js/urls.js')

# BOWER_COMPONENTS_ROOT = os.path.join(STATIC_ROOT, 'bower_components')

MONGO_LOCATION = {}
MONGO_DATABASE = {}
