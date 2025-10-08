

# from app.routes.geofence import geofence_bp
# import os
# from flask import Flask, send_from_directory
# from flask_cors import CORS
# from dotenv import load_dotenv
# from database import db
# from routes.campaign import campaign_bp
# from routes.poster import poster_bp
# from routes.shop import shop_bp
# from routes.fencinglogic import fence_logic
# # add these lines right after you import shop_bp in app.py (before registering)
# import inspect
# print("shop_bp from:", inspect.getfile(shop_bp._class) if hasattr(shop_bp, "class_") else shop_bp)
# print("shop_bp object:", shop_bp)

# # Load environment variables
# load_dotenv(".env")

# app = Flask(__name__)
# CORS(app)

# # Database config
# app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
# app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
# app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "replace_this_with_a_secret")
# app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "replace_this_with_jwt_secret")

# # Uploads folder (absolute path)
# app.config["UPLOAD_FOLDER"] = os.path.join(os.getcwd(), "uploads")
# os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

# # Initialize DB
# db.init_app(app)
# with app.app_context():
#     print("✅ Using DB:", app.config["SQLALCHEMY_DATABASE_URI"])
#     db.create_all()

# # Serve uploaded images
# @app.route("/uploads/<path:filename>")
# def serve_upload(filename):
#     full_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
#     print("📤 Serving file:", full_path)
#     return send_from_directory(app.config["UPLOAD_FOLDER"], filename)

# # Register blueprints (only once)
# app.register_blueprint(campaign_bp, url_prefix="/api/campaigns")
# app.register_blueprint(poster_bp, url_prefix="/api")
# app.register_blueprint(shop_bp, url_prefix="/shops")
# app.register_blueprint(geofence_bp,url_prefix="/api/geofence")
# app.register_blueprint(fence_logic,url_prefix="/api/geofence/callbacl")

# with app.app_context():
#     print("---- /shops RULES ----")
#     for rule in app.url_map.iter_rules():
#         if rule.rule.startswith("/shops"):
#             print(rule, "methods:", sorted(rule.methods))
#     print("----------------------")

# if __name__ == "__main__":
#     # Use env var to control debug on/off
#     debug_mode = os.getenv("FLASK_DEBUG", "False").lower() in ("1", "true", "yes")
#     # Optionally set host/port via env
#     host = os.getenv("FLASK_HOST", "0.0.0.0")
#     port = int(os.getenv("FLASK_PORT", "5000"))
#     app.run(host=host, port=port, debug=debug_mode)



from app.routes.geofence import geofence_bp
from app.nokia_client import get_device_location  # Import your location retriever
from app.routes.geofence import create_geofence_subscription  # Import your geofencing creator
import os
from flask import Flask, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv
from database import db
from routes.campaign import campaign_bp
from routes.poster import poster_bp
from routes.shop import shop_bp
from routes.fencinglogic import fence_logic
import psycopg2

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
app.register_blueprint(shop_bp, url_prefix="/shops")
app.register_blueprint(geofence_bp, url_prefix="/api/geofence")
app.register_blueprint(fence_logic, url_prefix="/api/geofence/callback")

# ------------------------------------------
# 🔁 Function to implement geofence setup
# ------------------------------------------
def implement_geofence():
    print("🚀 Initializing geofencing setup...")

    # 1️⃣ Connect to Postgres manually
    conn = psycopg2.connect(os.getenv("DATABASE_URL"))
    cursor = conn.cursor()

    # 2️⃣ Fetch all devices
    cursor.execute("SELECT uid, phone_number FROM devices;")
    devices = cursor.fetchall()
    print(f"📱 Found {len(devices)} devices to process...")

    # 3️⃣ Loop through devices
    for uid, phone_number in devices:
        print(f"🔍 Processing device: {uid} ({phone_number})")

        # Retrieve location
        try:
            location = get_device_location(phone_number)
            if "error" in location:
                print(f"❌ Failed to get location for {phone_number}: {location['error']}")
                continue

            lat = location["latitude"]
            lon = location["longitude"]
            radius = location.get("radius", 2000)

            # 4️⃣ Create geofence subscription
            create_res = create_geofence_subscription(phone_number, lat, lon, radius)
            print(f"🛰️ Geofence created for {phone_number}: {create_res}")

        except Exception as e:
            print(f"⚠️ Error processing {phone_number}: {e}")

    cursor.close()
    conn.close()
    print("✅ Geofencing setup completed for all devices.")


# ------------------------------------------
# Run Flask app
# ------------------------------------------
if __name__ == "__main__":
    debug_mode = os.getenv("FLASK_DEBUG", "False").lower() in ("1", "true", "yes")
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", "5000"))

    # ⚙️ Before starting the app, run geofence setup
    with app.app_context():
        implement_geofence()

    app.run(host=host, port=port, debug=debug_mode)
