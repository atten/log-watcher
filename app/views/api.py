import json
from flask import Response, g, request, jsonify

from app import app
from app.database import mongo_db, get_logs_by_uuid, get_logs_list, get_collections
from app.utils import str_to_int


@app.route('/api/v1/logs/')
def logs_list():
    collections = request.args.getlist('collection')
    limit = str_to_int(request.args.get('limit', 10))
    filters_str = request.args.get('filters_str', '')
    skip = [str_to_int(i) for i in request.args.getlist('skip')]

    try:
        filters = json.loads(filters_str)
    except ValueError:
        filters = {}

    return jsonify(get_logs_list(limit, skip, *collections, **filters))


@app.route('/api/v1/logs/by-uuid/<log_uuid>/')
def logs_by_uuid(log_uuid: str):
    collections = request.args.getlist('collection')
    d = get_logs_by_uuid(log_uuid, *collections)
    return jsonify(d)
