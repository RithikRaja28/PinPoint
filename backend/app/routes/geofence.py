from flask import Blueprint, request, jsonify
from ..nokia_client import verify_location_nokia

geofence_bp = Blueprint("geofence", __name__)

@geofence_bp.route("/trigger", methods=["POST"])
def trigger_geofence():
    data = request.json or {}
    print("📍 Geofence trigger received:", data)

    phone_number = data.get("phone_number", "+99999991000")
    lat = data.get("lat")
    lon = data.get("lon")
    timestamp = data.get("timestamp", "2025-10-07T12:00:00Z")  

    if not lat or not lon:
        return jsonify({"error": "Missing coordinates"}), 400

    verified = verify_location_nokia(phone_number, lat, lon, timestamp)

    if verified:
        return jsonify({"verified": True, "message": "Device is within area"}), 200
    else:
        return jsonify({"verified": False, "message": "Device not verified"}), 200
