from .routes.geofence import geofence_bp
app.register_blueprint(geofence_bp, url_prefix="/api/geofence")
