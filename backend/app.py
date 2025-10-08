from app.routes.geofence import geofence_bp
import os
from flask import Flask, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv
from database import db
from routes.campaign import campaign_bp
from routes.poster import poster_bp
from routes.shop import shop_bp
# add these lines right after you import shop_bp in app.py (before registering)
import inspect
print("shop_bp from:", inspect.getfile(shop_bp._class) if hasattr(shop_bp, "class_") else shop_bp)
print("shop_bp object:", shop_bp)

# Load environment variables
load_dotenv(".env")

app = Flask(_name_)
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

# Register blueprints (only once)
app.register_blueprint(campaign_bp, url_prefix="/api/campaigns")
app.register_blueprint(poster_bp, url_prefix="/api")
app.register_blueprint(shop_bp, url_prefix="/shops")
app.register_blueprint(geofence_bp,url_prefix="/api/geofence")
app.register_blueprint(geofence_bp,url_prefix="/api/geofence")

# Print URL map for debugging (inside app context so it has access to routes)
with app.app_context():
    print("---- /shops RULES ----")
    for rule in app.url_map.iter_rules():
        if rule.rule.startswith("/shops"):
            print(rule, "methods:", sorted(rule.methods))
    print("----------------------")

if _name_ == "_main_":
    # Use env var to control debug on/off
    debug_mode = os.getenv("FLASK_DEBUG", "False").lower() in ("1", "true", "yes")
    # Optionally set host/port via env
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", "5000"))
    app.run(host=host, port=port, debug=debug_mode)