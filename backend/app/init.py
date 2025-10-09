from .routes.geofence import geofence_bp
from routes.recommendation_route import recommend_bp
app.register_blueprint(geofence_bp, url_prefix="/api/geofence")
app.register_blueprint(recommend_bp, url_prefix="/api")
