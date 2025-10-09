
import json
from backend.app.nokia_client import create_geofence_subscription
from backend.app.routes.geofence import get_device_connectivity_status, get_device_location
from flask import Blueprint, request, jsonify, current_app
from database import db
import os
import psycopg2

os.load_dotenv(".env")

fence_logic = Blueprint("fence_logic", __name__)

@fence_logic.route("/", methods=["POST"])
def geofence_callback():
    try:
        conn = psycopg2.connect(os.getenv("DATABASE_URL"))
        cursor = conn.cursor()
        # 1️⃣ Get JSON payload from the callback
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data received"}), 400

        # 2️⃣ Pretty print the full payload for debugging
        print("📬 Callback Received:")
        print(json.dumps(data, indent=2))

        # 3️⃣ Extract useful details
        event_type = data.get("eventType", "unknown")
        device_info = data.get("device", {})
        device_number = device_info.get("phoneNumber", "unknown")
        event_time = data.get("eventTime", "unknown")

        device_number="+36719991000" #commment it once got the credits to work for any number


        # # Geofence area info (optional)
        # area_info = data.get("area", {})
        # latitude = area_info.get("center", {}).get("latitude")
        # longitude = area_info.get("center", {}).get("longitude")
        # radius = area_info.get("radius")
        
        # 4️⃣ Print extracted information
        print(f"📡 Device {device_number} triggered event: {event_type}")
        print(f"   - Time: {event_time}")
        # print(f"   - Location: lat={latitude}, lon={longitude}, radius={radius}")

        
        location = location = get_device_location({ "device": {"phoneNumber": device_number}, "maxAge": 60, })

        if not location or "error" in location:
            print(f"❌ Failed to get location for {device_number}: {location}")


        # 4️⃣ Parse location fields safely
        current_lat = float(location.get("latitude", 0))
        current_lon = float(location.get("longitude", 0))
        radius = int(location.get("radius", 2000))
        last_time = location.get("lastLocationTime", "N/A")

        print(f"📍 Device {device_number} -> lat: {current_lat}, lon: {current_lon}, radius: {radius}, time: {last_time}")
        tatus_success, status_result=get_device_connectivity_status(device_number)
        update_query = """
            UPDATE devices
            SET latitude = %s,
                longitude = %s,
                c_status=%s
            WHERE phone_number = %s;
        """
        cursor.execute(update_query, (current_lat, current_lon,status_result["connectivityStatus"],device_number))
        conn.commit()
        print(f"✅ Updated device {device_number} in DB with latest location.")

        create_res = create_geofence_subscription(device_number, current_lat, current_lon, radius)
        print(f"🛰️ Geofence created for {device_number}: {create_res}")

        #shops descovery logic create functions discover nearby shops so we can use for update geofence also

        #once shops discovered, iterate shops, find campains for that shop, invoke pushnotification to that user device using the FCM code



        return jsonify({"message": "Callback received successfully"}), 200

    except Exception as e:
        print("❌ Error handling callback:", e)
        return jsonify({"error": str(e)}), 500