from pymongo import MongoClient, DESCENDING
from funcy.calc import memoize

from app import app


def get_database():
    client = MongoClient(**app.config['MONGO_LOCATION'])
    db = getattr(client, app.config['MONGO_DATABASE'].pop('db', ''))
    db.authenticate(**app.config['MONGO_DATABASE'])
    return db


@memoize
def get_collections() -> [str]:
    return mongo_db.collection_names(False)


def get_logs_list(limit: int, skip: [int], *collections, **filters):
    ret = []

    for i, collection in enumerate(collections):
        skip_current = skip[i] if len(skip) > i else 0
        cursor = mongo_db[collection]\
            .find(filters, projection={'_id': 0})\
            .sort([("timestamp", DESCENDING)])\
            .skip(skip_current)\
            .limit(limit)

        for document in cursor:
            document['collection'] = collection
            ret.append(document)

    return sorted(ret, key=lambda x: x['timestamp'], reverse=True)[:limit]


def get_logs_by_uuid(log_uuid: str, *collections):
    ret = []

    for collection in collections:
        cursor = mongo_db[collection].find({
            'data.log_uuid': log_uuid
        }, {'_id': 0})

        for document in cursor:
            document['collection'] = collection
            ret.append(document)

    return sorted(ret, key=lambda x: x['data']['log_sequence'])

mongo_db = get_database()
