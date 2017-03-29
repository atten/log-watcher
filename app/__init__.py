import os.path

from flask import Flask
from flask_script import Manager

app = Flask(__name__)
manager = Manager(app)


def init_app(settings_file='local_settings'):
    # from flask_babel import Babel
    # from raven.contrib.flask import Sentry

    # # Babel
    # babel = Babel(app)
    #
    # # Sentry
    # sentry = Sentry()
    # sentry.init_app(app)

    # from flask.ext.bower import Bower
    #
    # Bower(app)
    configure_app(settings_file)

    from app import permissions, database, context_processors, management
    from app.views import api, views


def configure_app(settings_file):
    settings_path = os.path.join(os.path.dirname(__file__), settings_file) + '.py'

    if not os.path.exists(settings_path):
        with open(settings_path, 'w') as f:
            f.write("from .settings import *")
            f.close()

    app.config.from_object('app.{0}'.format(settings_file))
