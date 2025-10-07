from flask import Flask
from .db import db
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS

def create_app(config_object="app.config.Config"):
    app = Flask(__name__)
    app.config.from_object(config_object)

    CORS(app)
    db.init_app(app)
    migrate = Migrate(app, db)
    jwt = JWTManager(app)

    # import and register blueprints
    from .routes.auth import auth_bp
    from .routes.shops import shops_bp
    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(shops_bp, url_prefix="/api/shops")

    return app
