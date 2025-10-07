from flask import Blueprint, request, jsonify
from ..nokia_client import (
    verify_location_nokia,
    create_geofence_subscription,
    retrieve_geofence_subscription,
    delete_geofence_subscription,
    list_geofence_subscriptions
)

geofence_bp = Blueprint("geofence", __name__)

# Trigger Geofence Verification (existing)

@geofence_bp.route("/trigger", methods=["POST"])
def trigger_geofence():
    """
    Verify if a user's device is within a specified geofence.
    Used for offer redemption, fraud prevention, etc.
    """
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

#  Create Geofencing Subscription (for shops)

@geofence_bp.route("/create", methods=["POST"])
def create_subscription():
    """
    Create a geofencing subscription for a shop or campaign.
    """
    data = request.json or {}
    phone_number = data.get("phone_number", "+99999991000")
    lat = data.get("lat")
    lon = data.get("lon")
    radius = data.get("radius", 2000)

    if not lat or not lon:
        return jsonify({"error": "Missing coordinates"}), 400

    result = create_geofence_subscription(phone_number, lat, lon, radius)
    return jsonify(result), 200



# Retrieve Single Subscription

@geofence_bp.route("/subscription/<subscription_id>", methods=["GET"])
def get_subscription(subscription_id):
    """
    Retrieve a single geofence subscription by ID.
    """
    result = retrieve_geofence_subscription(subscription_id)
    return jsonify(result), 200



# Delete Geofencing Subscription

@geofence_bp.route("/subscription/<subscription_id>", methods=["DELETE"])
def remove_subscription(subscription_id):
    """
    Delete a geofence subscription by ID.
    """
    result = delete_geofence_subscription(subscription_id)
    return jsonify(result), 200


# List All Subscriptions

@geofence_bp.route("/subscriptions", methods=["GET"])
def list_subscriptions():
    """
    List all active geofence subscriptions.
    """
    result = list_geofence_subscriptions()
    return jsonify(result), 200
