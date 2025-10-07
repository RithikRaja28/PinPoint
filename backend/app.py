import os
from flask import Flask, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv
from database import db
from routes.campaign import campaign_bp
from routes.poster import poster_bp

# Load environment variables
load_dotenv(".env")

app = Flask(__name__)
CORS(app)

# Database config
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "replace_this_with_a_secret")
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "replace_this_with_jwt_secret")

# Uploads folder (absolute path)
app.config["UPLOAD_FOLDER"] = os.path.join(os.getcwd(), "uploads")
os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

# Initialize DB
db.init_app(app)
with app.app_context():
    print("✅ Using DB:", app.config["SQLALCHEMY_DATABASE_URI"])
    db.create_all()

# Serve uploaded images
@app.route("/uploads/<path:filename>")
def serve_upload(filename):
    full_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
    print("📤 Serving file:", full_path)
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)

# Register blueprints
app.register_blueprint(campaign_bp, url_prefix="/api/campaigns")
app.register_blueprint(poster_bp, url_prefix="/api")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
import os
from flask import Flask, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv
from database import db
from routes.campaign import campaign_bp
from routes.poster import poster_bp

# Load environment variables
load_dotenv(".env")

app = Flask(__name__)
CORS(app)

# Database config
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "replace_this_with_a_secret")
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "replace_this_with_jwt_secret")

# Uploads folder (absolute path)
app.config["UPLOAD_FOLDER"] = os.path.join(os.getcwd(), "uploads")
os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

# Initialize DB
db.init_app(app)
with app.app_context():
    print("✅ Using DB:", app.config["SQLALCHEMY_DATABASE_URI"])
    db.create_all()

# Serve uploaded images
@app.route("/uploads/<path:filename>")
def serve_upload(filename):
    full_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
    print("📤 Serving file:", full_path)
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)

# Register blueprints
app.register_blueprint(campaign_bp, url_prefix="/api/campaigns")
app.register_blueprint(poster_bp, url_prefix="/api")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
