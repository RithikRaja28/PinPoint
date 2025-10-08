
import json
from backend.app.nokia_client import create_geofence_subscription
from flask import Blueprint, request, jsonify, current_app
from database import db
from models.campaign_model import CampaignModel

fence_logic = Blueprint("fence_logic", __name__)

@fence_logic.route("/", methods=["POST"])
def geofence_callback():
    try:
        data = request.get_json()
        print("📬 Callback Received:")
        print(json.dumps(data, indent=2))

        # Optional: Extract details for use
        event_type = data.get("eventType")
        device = data.get("device", {}).get("phoneNumber")
        timestamp = data.get("eventTime")

        print(f"📡 Device {device} triggered event: {event_type} at {timestamp}")
        create_geofence_subscription(phone_number: str, lat: float, lon: float, radius: int = 2000p)
        # Example: Save to DB (if needed)
        # new_event = CampaignModel(device=device, event=event_type, time=timestamp)
        # db.session.add(new_event)
        # db.session.commit()

        return jsonify({"message": "Callback received successfully"}), 200
    except Exception as e:
        print("❌ Error handling callback:", e)
        return jsonify({"error": str(e)}), 500