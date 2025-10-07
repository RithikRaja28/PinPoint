from flask import Blueprint, request, jsonify
from ..nokia_client import (
    verify_location_nokia,
    create_geofence_subscription,
    retrieve_geofence_subscription,
    delete_geofence_subscription,
    list_geofence_subscriptions,
    check_sim_swap,
    retrieve_sim_swap_date
)

geofence_bp = Blueprint("geofence", __name__)

# Verify Device Location (Existing)

@geofence_bp.route("/trigger", methods=["POST"])
def trigger_geofence():
    """
    Verify if a user's device is inside a specific geofence.
    Used during offer redemption, fraud prevention, etc.
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

    return jsonify({
        "verified": verified,
        "message": "Device is within geofence" if verified else "Device not verified"
    }), 200


# Create Geofencing Subscription (Shop Use)

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


# Retrieve Single Geofencing Subscription
@geofence_bp.route("/subscription/<subscription_id>", methods=["GET"])
def get_subscription(subscription_id):
    """
    Retrieve a single geofencing subscription by its ID.
    """
    print(f"🔍 Retrieving subscription: {subscription_id}")
    result = retrieve_geofence_subscription(subscription_id)
    return jsonify(result), 200

# Delete Geofencing Subscription
@geofence_bp.route("/subscription/<subscription_id>", methods=["DELETE"])
def remove_subscription(subscription_id):
    """
    Delete a geofencing subscription by its ID.
    """
    print(f"🗑️ Deleting subscription: {subscription_id}")
    result = delete_geofence_subscription(subscription_id)
    return jsonify(result), 200


#List All Active Subscriptions

@geofence_bp.route("/subscriptions", methods=["GET"])
def list_subscriptions():
    """
    List all active geofencing subscriptions.
    """
    print("📋 Listing all active subscriptions")
    result = list_geofence_subscriptions()
    return jsonify(result), 200


#SIM Swap Check

@geofence_bp.route("/simswap/check", methods=["POST"])
def simswap_check():
    """
    Check if a user's SIM has been swapped recently (anti-fraud check).
    """
    data = request.json or {}
    phone_number = data.get("phone_number", "+99999991000")
    max_age = data.get("max_age", 240)

    print(f"📡 Checking SIM swap for: {phone_number}")
    result = check_sim_swap(phone_number, max_age)
    return jsonify(result), 200

# Retrieve SIM Swap Date

@geofence_bp.route("/simswap/retrieve", methods=["POST"])
def simswap_retrieve():
    """
    Retrieve the last SIM swap date/time for a given phone number.
    """
    data = request.json or {}
    phone_number = data.get("phone_number", "+99999991000")

    print(f"📡 Retrieving SIM swap date for: {phone_number}")
    result = retrieve_sim_swap_date(phone_number)
    return jsonify(result), 200


# Combined Redemption Route (Optional)

@geofence_bp.route("/redeem", methods=["POST"])
def redeem_offer():
    """
    Combined route for verifying geofence and SIM swap together.
    Ideal for secure offer redemption.
    """
    data = request.json or {}
    phone_number = data.get("phone_number", "+99999991000")
    lat = data.get("lat")
    lon = data.get("lon")

    if not lat or not lon:
        return jsonify({"error": "Missing coordinates"}), 400

    print(f"🎯 Redeem attempt: {phone_number} at {lat},{lon}")

    # Step 1: Check location
    inside = verify_location_nokia(phone_number, lat, lon)
    # Step 2: Check SIM status
    sim_info = check_sim_swap(phone_number)
    changed = sim_info.get("changed", True)

    if inside and not changed:
        return jsonify({
            "success": True,
            "verified_location": True,
            "sim_changed": False,
            "message": "✅ Redemption Approved"
        }), 200
    else:
        reason = "SIM recently changed" if changed else "Outside geofence"
        return jsonify({
            "success": False,
            "verified_location": inside,
            "sim_changed": changed,
            "message": f"❌ Redemption Denied: {reason}"
        }), 403
