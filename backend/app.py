import os
from flask import Flask
from flask_cors import CORS
from database import db
from routes.campaign import campaign_bp
from routes.poster import poster_bp
from dotenv import load_dotenv  # ✅ load .env

# Load .env file
load_dotenv(".env")

app = Flask(__name__)
CORS(app)

# Postgres DB URL from .env
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
    "DATABASE_URL"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "replace_this_with_a_secret")
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "replace_this_with_jwt_secret")

# Initialize DB
db.init_app(app)

with app.app_context():
    print("Using DB:", app.config["SQLALCHEMY_DATABASE_URI"])  # ✅ check connection
    db.create_all()

# Register blueprints
app.register_blueprint(campaign_bp, url_prefix="/api/campaigns")
app.register_blueprint(poster_bp, url_prefix="/api")

if __name__ == "__main__":
    os.makedirs(os.getenv("UPLOAD_FOLDER", "uploads"), exist_ok=True)
    app.run(host="0.0.0.0", port=5000, debug=True)
