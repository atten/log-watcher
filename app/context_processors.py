from app import app
from app.database import get_collections


@app.context_processor
def collections():
    return dict(collections=get_collections())
