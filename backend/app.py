import os
import psycopg2
from flask import Flask, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv
from database import db
from routes.campaign import campaign_bp
from routes.poster import poster_bp
from routes.shop import shop_bp
from routes.devices import device_bp
# from routes.fencinglogic import fence_logic
from app.routes.geofence import geofence_bp, get_device_location, create_geofence_subscription

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


# ----------------------------------------------------------
# Serve uploaded images
# ----------------------------------------------------------
@app.route("/uploads/<path:filename>")
def serve_upload(filename):
    full_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
    print("📤 Serving file:", full_path)
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)


# ----------------------------------------------------------
# Register blueprints
# ----------------------------------------------------------
app.register_blueprint(campaign_bp, url_prefix="/api/campaigns")
app.register_blueprint(poster_bp, url_prefix="/api")
app.register_blueprint(shop_bp, url_prefix="/shops")
app.register_blueprint(geofence_bp, url_prefix="/api/geofence")
app.register_blueprint(device_bp, url_prefix="/device")
# app.register_blueprint(fence_logic, url_prefix="/api/geofence/callback")


# ----------------------------------------------------------
# Main logic for geofencing setup
# ----------------------------------------------------------
def implement_geofence():
    print("🚀 Initializing geofencing setup...")

    try:
        conn = psycopg2.connect(os.getenv("DATABASE_URL"))
        cursor = conn.cursor()

        # 1️⃣ Fetch all devices
        cursor.execute("SELECT uid, phone_number FROM devices;")
        devices = cursor.fetchall()
        print(f"📱 Found {len(devices)} devices to process...")

        # 2️⃣ Process each device
        for uid, phone_number in devices:
            print(f"🔍 Processing device: {uid} ({phone_number})")

            # (Optional) Hardcode phone number for testing
            phone_number = "+36719991000"  # comment once your API credits are ready

            try:
                # 3️⃣ Retrieve location from API
                print(f"📍 Retrieving location for {phone_number} ...")
                location = get_device_location(phone_number)

                if not location or "error" in location:
                    print(f"❌ Failed to get location for {phone_number}: {location}")
                    continue

                # 4️⃣ Parse location fields safely
                current_lat = float(location.get("latitude", 0))
                current_lon = float(location.get("longitude", 0))
                radius = int(location.get("radius", 2000))
                last_time = location.get("lastLocationTime", "N/A")

                print(f"📍 Device {phone_number} -> lat: {current_lat}, lon: {current_lon}, radius: {radius}, time: {last_time}")

                # 5️⃣ Create geofence subscription
                create_res = create_geofence_subscription(phone_number, current_lat, current_lon, radius)
                print(f"🛰 Geofence created for {phone_number}: {create_res}")

            except Exception as inner_e:
                print(f"⚠ Error processing {phone_number}: {inner_e}")

        cursor.close()
        conn.close()
        print("✅ Geofencing setup completed for all devices.")

    except Exception as outer_e:
        print(f"❌ Error connecting to database or initializing geofence: {outer_e}")


# ----------------------------------------------------------
# Run Flask app
# ----------------------------------------------------------
if __name__ == "__main__":
    debug_mode = os.getenv("FLASK_DEBUG", "False").lower() in ("1", "true", "yes")
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", "5000"))

    # ⚙ Run geofence setup before app starts
    # with app.app_context():
    #     implement_geofence()

    app.run(host=host, port=port, debug=debug_mode)


