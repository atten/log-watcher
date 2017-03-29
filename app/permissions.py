import os
from typing import Any, Dict, List
from collections import defaultdict

from flask import Response, g, request
from funcy.calc import memoize

from app import app


@memoize
def valid_credentials():
    """
    Парсит файл AUTH_FILE, объявленный в настройках, возвращает набор валидных реквизитов.
    :return: dict, key - разрешённый ip адрес, val - [('login1', 'pass1'), ('login2', 'pass2')]
    """
    path_file = app.config['AUTH_FILE']
    if not os.path.exists(path_file):
        raise FileExistsError('Could not find {}'.format(path_file))

    d = defaultdict(list)
    with open(path_file, 'r') as file:
        for line in file.readlines():
            l = line.rstrip().split(':')
            if len(l) != 3:
                continue
            key = '127.0.0.1' if l[0] == 'localhost' else l[0]
            d[key].append(tuple(l[1:]))
    return d


def check_authorization(ip_addr: str, auth: Any) -> bool:
    if not auth or (auth.username, auth.password) not in valid_credentials().get(ip_addr, []):
        return False
    return True


@app.before_request
def before_request():
    if not check_authorization(request.remote_addr, request.authorization):
        msg = 'Could not verify your access level for that URL. You have to login with proper credentials.'
        return Response(msg, 401, {'WWW-Authenticate': 'Basic realm="Login Required"'})
    # some user exists, save him
    setattr(g, 'user', request.authorization.username)
