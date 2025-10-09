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
import os
import requests
import json
geofence_bp = Blueprint("geofence", __name__)

# Verify Device Location (Existing)

NOKIA_BASE_URL = os.getenv("NOKIA_BASE_URL")
NOKIA_RAPIDAPI_KEY = os.getenv("NOKIA_RAPIDAPI_KEY")
NOKIA_RAPIDAPI_HOST = os.getenv("NOKIA_RAPIDAPI_HOST")

HEADERS = {
    "Content-Type": "application/json",
    "X-RapidAPI-Key": NOKIA_RAPIDAPI_KEY,
    "X-RapidAPI-Host": NOKIA_RAPIDAPI_HOST
}

# ✅ Updated function to send correct payload
def get_device_location(device_payload: dict):
    """
    Retrieve the current or last known location of a device from Nokia Network-as-Code.
    """
    url = f"{NOKIA_BASE_URL}/location-retrieval/v0/retrieve"

    try:
        print("📤 Sending payload to Nokia API:", json.dumps(device_payload, indent=2))

        res = requests.post(
            url,
            data=json.dumps(device_payload),
            headers=HEADERS,
            timeout=15
        )

        print("📡 Nokia API Response:", res.status_code, res.text)

        # ✅ Handle successful response
        if res.status_code == 200:
            data = res.json()

            # Since the API returns directly (not inside "location")
            area = data.get("area", {}) or {}
            center = area.get("center", {}) or {}

            return {
                "lastLocationTime": data.get("lastLocationTime"),
                "latitude": center.get("latitude"),
                "longitude": center.get("longitude"),
                "radius": area.get("radius"),
                "areaType": area.get("areaType"),
            }

        # ❌ Any other status code = error
        return {
            "error": f"Unexpected response: {res.status_code} - {res.text}"
        }

    except Exception as e:
        print("❌ Error retrieving device location:", e)
        return {"error": str(e)}
    
@geofence_bp.route("/device/status/subscribe", methods=["POST"])
def subscribe_device_status():
    """
    Subscribe to notifications for device status changes.
    Only the phone number comes from frontend; everything else is fixed.
    """
    if not request.is_json:
        return jsonify({
            "success": False,
            "error": "Request content type must be application/json"
        }), 415

    data = request.get_json()
    phone_number = data.get("phoneNumber")  # frontend sends only this

    if not phone_number:
        return jsonify({
            "success": False,
            "error": "Missing phoneNumber"
        }), 400

    # Fixed subscription payload
    payload = {
        "subscriptionDetail": {
            "device": {"phoneNumber": phone_number},
            "type": "org.camaraproject.device-status.v0.roaming-status"
        },
        "subscriptionExpireTime": "2026-01-17T13:18:23.682Z",
        "webhook": {
            "notificationUrl": "https://application-server.com",
            "notificationAuthToken": "c8974e592c2fa383d4a3960714"
        }
    }

    url = f"{NOKIA_BASE_URL}/device-status/v0/subscriptions"

    try:
        res = requests.post(url, data=json.dumps(payload), headers=HEADERS, timeout=15)
        print("📡 Device Status Subscription Response:", res.status_code, res.text)

        if res.status_code in [200, 201]:
            return jsonify({"success": True, "subscription": res.json()}), 200
        else:
            return jsonify({"success": False, "error": f"Unexpected response: {res.status_code} - {res.text}"}), 500

    except Exception as e:
        print("❌ Error creating device status subscription:", e)
        return jsonify({"success": False, "error": str(e)}), 500

@geofence_bp.route("/device/status/connectivity", methods=["POST"])
def get_device_connectivity_status():
    """
    Get the connectivity status of a mobile device.
    Returns one of: CONNECTED_SMS, CONNECTED_DATA, NOT_CONNECTED
    """
    if not request.is_json:
        return jsonify({
            "success": False,
            "error": "Request content type must be application/json"
        }), 415

    data = request.get_json()
    print("📍 Received request data for connectivity:", json.dumps(data, indent=2))

    # Validate phone number
    phone_number = data.get("device", {}).get("phoneNumber")
    if not phone_number:
        return jsonify({"success": False, "error": "Missing device.phoneNumber"}), 400

    url = f"{NOKIA_BASE_URL}/device-status/v0/connectivity"
    payload = {"device": {"phoneNumber": phone_number}}

    try:
        res = requests.post(url, data=json.dumps(payload), headers=HEADERS, timeout=15)
        print("📡 Connectivity API Response:", res.status_code, res.text)

        if res.status_code == 200:
            return jsonify({"success": True, "connectivityStatus": res.json().get("connectivityStatus")}), 200
        else:
            return jsonify({"success": False, "error": f"Unexpected response: {res.status_code} - {res.text}"}), 500

    except Exception as e:
        print("❌ Error getting device connectivity status:", e)
        return jsonify({"success": False, "error": str(e)}), 500


# # Retrieve Device Location
# @geofence_bp.route("/location/retrieve", methods=["POST"])
# def retrieve_location_and_status():
#     if not request.is_json:
#         return jsonify({
#             "success": False,
#             "error": "Request content type must be application/json",
#             "hint": "Add 'Content-Type: application/json' in your request headers."
#         }), 415

#     data = request.get_json()
#     print("📍 Received request data:", json.dumps(data, indent=2))

#     if "device" not in data or "phoneNumber" not in data["device"]:
#         return jsonify({
#             "success": False,
#             "error": "Invalid payload. Must include device.phoneNumber."
#         }), 400

#     phone_number = data["device"]["phoneNumber"]

#     # 1️⃣ Get device location
#     location_result = get_device_location(data)
#     if "error" in location_result:
#         print("❌ Location retrieval failed:", location_result["error"])
#         return jsonify({
#             "success": False,
#             "error": location_result["error"]
#         }), 500

#     # 2️⃣ Subscribe device status
#     subscription_payload = {
#         "subscriptionDetail": {
#             "device": {"phoneNumber": phone_number},
#             "type": "org.camaraproject.device-status.v0.roaming-status"
#         },
#         "subscriptionExpireTime": "2026-01-17T13:18:23.682Z",
#         "webhook": {
#             "notificationUrl": "https://application-server.com",
#             "notificationAuthToken": "c8974e592c2fa383d4a3960714"
#         }
#     }

#     print("📤 Subscription API Payload:", json.dumps(subscription_payload, indent=2))

#     subscription_url = f"{NOKIA_BASE_URL}/device-status/v0/subscriptions"
#     try:
#         sub_res = requests.post(subscription_url, data=json.dumps(subscription_payload), headers=HEADERS, timeout=15)
#         print("📡 Device Status Subscription Response Code:", sub_res.status_code)
#         print("📡 Device Status Subscription Response Body:", sub_res.text)
#         subscription_success = sub_res.status_code in [200, 201]
#         subscription_result = sub_res.json() if subscription_success else {"error": f"Unexpected response: {sub_res.status_code} - {sub_res.text}"}
#     except Exception as e:
#         subscription_result = {"error": str(e)}
#         subscription_success = False
#         print("❌ Subscription API Exception:", e)

#     # 3️⃣ Get device connectivity status
#     status_payload = {
#         "device": {"phoneNumber": phone_number}
#     }
#     status_url = f"{NOKIA_BASE_URL}/device-status/v0/connectivity"

#     print("📤 Connectivity Status API Payload:", json.dumps(status_payload, indent=2))

#     try:
#         status_res = requests.post(status_url, data=json.dumps(status_payload), headers=HEADERS, timeout=15)
#         print("📡 Device Status Response Code:", status_res.status_code)
#         print("📡 Device Status Response Body:", status_res.text)
#         status_success = status_res.status_code in [200, 201]
#         status_result = status_res.json() if status_success else {"error": f"Unexpected response: {status_res.status_code} - {status_res.text}"}
#     except Exception as e:
#         status_result = {"error": str(e)}
#         status_success = False
#         print("❌ Device Status API Exception:", e)

#     # ✅ Return combined response
#     return jsonify({
#         "success": True,
#         "location": location_result,
#         "subscription": {
#             "success": subscription_success,
#             "data": subscription_result
#         },
#         "device_status": {
#             "success": status_success,
#             "data": status_result
#         },
#         "message": "✅ Device location retrieved, subscription processed, and device status fetched."
#     }), 200


# ---------------------------------------------------------------------
# 🔹 Function: Subscribe Device to Status Updates
# ---------------------------------------------------------------------
def subscribe_device_status(phone_number):
    subscription_payload = {
        "subscriptionDetail": {
            "device": {"phoneNumber": phone_number},
            "type": "org.camaraproject.device-status.v0.roaming-status"
        },
        "subscriptionExpireTime": "2026-01-17T13:18:23.682Z",
        "webhook": {
            "notificationUrl": "https://application-server.com",
            "notificationAuthToken": "c8974e592c2fa383d4a3960714"
        }
    }

    print("📤 Subscription API Payload:", json.dumps(subscription_payload, indent=2))
    subscription_url = f"{NOKIA_BASE_URL}/device-status/v0/subscriptions"

    try:
        response = requests.post(
            subscription_url,
            data=json.dumps(subscription_payload),
            headers=HEADERS,
            timeout=15
        )
        print("📡 Device Status Subscription Response Code:", response.status_code)
        print("📡 Device Status Subscription Response Body:", response.text)

        success = response.status_code in [200, 201]
        result = response.json() if success else {
            "error": f"Unexpected response: {response.status_code} - {response.text}"
        }
        return success, result

    except Exception as e:
        print("❌ Subscription API Exception:", e)
        return False, {"error": str(e)}


# ---------------------------------------------------------------------
# 🔹 Function: Get Device Connectivity Status
# ---------------------------------------------------------------------
def get_device_connectivity_status(phone_number):
    status_payload = {
        "device": {"phoneNumber": phone_number}
    }

    print("📤 Connectivity Status API Payload:", json.dumps(status_payload, indent=2))
    status_url = f"{NOKIA_BASE_URL}/device-status/v0/connectivity"

    try:
        response = requests.post(
            status_url,
            data=json.dumps(status_payload),
            headers=HEADERS,
            timeout=15
        )
        print("📡 Device Status Response Code:", response.status_code)
        print("📡 Device Status Response Body:", response.text)

        success = response.status_code in [200, 201]
        result = response.json() if success else {
            "error": f"Unexpected response: {response.status_code} - {response.text}"
        }
        return success, result

    except Exception as e:
        print("❌ Device Status API Exception:", e)
        return False, {"error": str(e)}




@geofence_bp.route("/location/cstatus",method=["POST"])
def get_connectivity_status():
    data = request.get_json()
    phone_number=data["phoneNumber"]
    subscription_success, subscription_result = subscribe_device_status(phone_number)
    # 3️⃣ Get device connectivity status
    status_success, status_result = get_device_connectivity_status(phone_number)

    return jsonify({
        "data": status_result,
        "message": "✅ Device location retrieved, subscription processed, and device status fetched."
    }), 200







# ---------------------------------------------------------------------
# 🔹 Main API: Retrieve Device Location + Subscription + Status
# ---------------------------------------------------------------------
@geofence_bp.route("/location/retrieve", methods=["POST"])
def retrieve_location_and_status():
    if not request.is_json:
        return jsonify({
            "success": False,
            "error": "Request content type must be application/json",
            "hint": "Add 'Content-Type: application/json' in your request headers."
        }), 415

    data = request.get_json()
    print("📍 Received request data:", json.dumps(data, indent=2))

    if "device" not in data or "phoneNumber" not in data["device"]:
        return jsonify({
            "success": False,
            "error": "Invalid payload. Must include device.phoneNumber."
        }), 400

    phone_number = data["device"]["phoneNumber"]

    # 1️⃣ Get device location
    location_result = get_device_location(data)
    if "error" in location_result:
        print("❌ Location retrieval failed:", location_result["error"])
        return jsonify({
            "success": False,
            "error": location_result["error"]
        }), 500

    # 2️⃣ Subscribe to device status
    subscription_success, subscription_result = subscribe_device_status(phone_number)

    # 3️⃣ Get device connectivity status
    status_success, status_result = get_device_connectivity_status(phone_number)

    # ✅ Return combined response
    return jsonify({
        "success": True,
        "location": location_result,
        "subscription": {
            "success": subscription_success,
            "data": subscription_result
        },
        "device_status": {
            "success": status_success,
            "status": status_result["connectivityStatus"]
        },
        "message": "✅ Device location retrieved, subscription processed, and device status fetched."
    }), 200

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
    print(f"🗑 Deleting subscription: {subscription_id}")
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