from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from .db import db
from config import Config
from .routes.geofence import geofence_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    CORS(app)
    db.init_app(app)
    JWTManager(app)

    from .routes.auth import auth_bp
    from .routes.shops import shops_bp
    from .routes.campaigns import campaigns_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(shops_bp, url_prefix='/api/shops')
    app.register_blueprint(campaigns_bp, url_prefix='/api/campaigns')
    app.register_blueprint(geofence_bp, url_prefix="/api/geofence")

    with app.app_context():
        from .models import User, Shop, Campaign
        db.create_all()
        print('✅ Database tables ensured')

    @app.route('/')
    def home():
        return {'message': 'PinPoint Backend (Flask + PostGIS) running ✅'}

    return app