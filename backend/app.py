from flask import Flask
from flask_cors import CORS
from database import db
from routes.campaign import campaign_bp
import os

app = Flask(__name__)
CORS(app)

# Postgres DB URL
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
    "DATABASE_URL", "sqlite:///campaigns.db"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)

with app.app_context():
    db.create_all()

app.register_blueprint(campaign_bp, url_prefix="/api/campaigns")

if __name__ == "__main__":
    os.makedirs(os.getenv("UPLOAD_FOLDER", "uploads"), exist_ok=True)
    app.run(host="0.0.0.0", port=5000, debug=True)
