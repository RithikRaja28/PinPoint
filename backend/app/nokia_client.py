import os
import json
import requests
import certifi

# Nokia Network-as-Code (RapidAPI) Config
NOKIA_BASE_URL = os.getenv("NOKIA_BASE_URL", "https://network-as-code.p-eu.rapidapi.com")
NOKIA_RAPIDAPI_KEY = os.getenv("NOKIA_RAPIDAPI_KEY")
NOKIA_RAPIDAPI_HOST = os.getenv("NOKIA_RAPIDAPI_HOST", "network-as-code.nokia.rapidapi.com")

HEADERS = {
    "x-rapidapi-key": NOKIA_RAPIDAPI_KEY,
    "x-rapidapi-host": NOKIA_RAPIDAPI_HOST,
    "Content-Type": "application/json"
}

# Create Geofencing Subscription
def create_geofence_subscription(phone_number: str, lat: float, lon: float, radius: int = 2000):
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions"
    payload = {
        "protocol": "HTTP",
        "sink": "https://your-backend-domain.com/api/geofence/callback",
        "types": ["org.camaraproject.geofencing-subscriptions.v0.area-entered"],
        "config": {
            "subscriptionDetail": {
                "device": {"phoneNumber": phone_number},
                "area": {"areaType": "CIRCLE", "center": {"latitude": lat, "longitude": lon}, "radius": radius}
            },
            "initialEvent": True,
            "subscriptionMaxEvents": 10,
            "subscriptionExpireTime": "2045-03-22T05:40:58.469Z"
        }
    }
    try:
        res = requests.post(url, data=json.dumps(payload), headers=HEADERS, verify=certifi.where(), timeout=15)
        print("📡 Create Geofence Response:", res.status_code, res.text)
        return res.json()
    except Exception as e:
        print("❌ Error creating geofence subscription:", e)
        return {"error": str(e)}

# Retrieve Geofencing Subscription
def retrieve_geofence_subscription(subscription_id: str):
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions/{subscription_id}"
    try:
        res = requests.get(url, headers=HEADERS, verify=certifi.where(), timeout=15)
        print("📡 Retrieve Subscription Response:", res.status_code, res.text)
        return res.json()
    except Exception as e:
        print("❌ Error retrieving geofence subscription:", e)
        return {"error": str(e)}

# Delete Geofencing Subscription
def delete_geofence_subscription(subscription_id: str):
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions/{subscription_id}"
    try:
        res = requests.delete(url, headers=HEADERS, verify=certifi.where(), timeout=15)
        print("🗑️ Delete Geofence Response:", res.status_code, res.text)
        return {"status": res.status_code, "response": res.text}
    except Exception as e:
        print("❌ Error deleting geofence subscription:", e)
        return {"error": str(e)}

# List All Geofencing Subscriptions
def list_geofence_subscriptions():
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions"
    try:
        res = requests.get(url, headers=HEADERS, verify=certifi.where(), timeout=15)
        print("📋 List Subscriptions Response:", res.status_code, res.text)
        return res.json()
    except Exception as e:
        print("❌ Error listing subscriptions:", e)
        return {"error": str(e)}

# Verify Device Location
def verify_location_nokia(phone_number: str, lat: float, lon: float, timestamp: str = None, radius: float = 50000) -> bool:
    url = f"{NOKIA_BASE_URL}/location-verification/v1/verify"
    payload = {
        "device": {"phoneNumber": phone_number},
        "area": {"areaType": "CIRCLE", "center": {"latitude": lat, "longitude": lon}, "radius": radius}
    }
    try:
        res = requests.post(url, data=json.dumps(payload), headers=HEADERS, verify=certifi.where(), timeout=15)
        print("📡 Location Verify Response:", res.status_code, res.text)
        if res.status_code == 200:
            data = res.json()
            return data.get("verificationResult", "").upper() == "TRUE"
        return False
    except Exception as e:
        print("❌ Nokia Verify Location Error:", e)
        return False

# SIM Swap Check
def check_sim_swap(phone_number: str, max_age: int = 240):
    url = f"{NOKIA_BASE_URL}/passthrough/camara/v1/sim-swap/sim-swap/v0/check"
    payload = {"phoneNumber": phone_number, "maxAge": max_age}
    try:
        res = requests.post(url, data=json.dumps(payload), headers=HEADERS, verify=certifi.where(), timeout=15)
        print("📡 SIM Swap Check Response:", res.status_code, res.text)
        return res.json()
    except Exception as e:
        print("❌ SIM Swap Check Error:", e)
        return {"error": str(e)}

# SIM Swap Retrieve Date
def retrieve_sim_swap_date(phone_number: str):
    url = f"{NOKIA_BASE_URL}/passthrough/camara/v1/sim-swap/sim-swap/v0/retrieve-date"
    payload = {"phoneNumber": phone_number}
    try:
        res = requests.post(url, data=json.dumps(payload), headers=HEADERS, verify=certifi.where(), timeout=15)
        print("📡 SIM Swap Retrieve Response:", res.status_code, res.text)
        return res.json()
    except Exception as e:
        print("❌ SIM Swap Retrieve Error:", e)
        return {"error": str(e)}
