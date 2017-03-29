Install
-------
```
pip install -r requirements.txt

cd static/
bower install ractive semantic-ui lscache
cd ..

./manage.py generate_js_urls
```


Configure
---------

local_settings.py:
```
from .settings import *

DEBUG = True    # if needed

MONGO_LOCATION = {
    'host': '...',  # default: localhost
    'port': '...',  # default: 27017
}

MONGO_DATABASE = {
    'db': '...',
    'name': '...',
    'password': '...',
}
```

data/auth:
```
localhost:user1:pass1
localhost:user2:pass2
...
```

Run
---
```
./manage.py runserver
```