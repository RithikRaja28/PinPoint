from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from .db import db
from config import Config


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

    with app.app_context():
        from .models import User, Shop, Campaign
        db.create_all()
        print('✅ Database tables ensured')

    @app.route('/')
    def home():
        return {'message': 'PinPoint Backend (Flask + PostGIS) running ✅'}

    return app