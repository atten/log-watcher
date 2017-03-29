from app import app, init_app, manager


@manager.command
def runserver():
    app.run(host='localhost', port=8211)


if __name__ == '__main__':
    init_app('local_settings')
    manager.run()
