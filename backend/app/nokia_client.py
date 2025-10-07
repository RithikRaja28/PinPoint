import os
import json
import requests
import certifi

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
    """
    Creates a geofence subscription that triggers when a device enters a defined area.
    """
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions"

    payload = {
        "protocol": "HTTP",
        "sink": "https://your-backend-domain.com/api/geofence/callback",  
        "types": ["org.camaraproject.geofencing-subscriptions.v0.area-entered"],
        "config": {
            "subscriptionDetail": {
                "device": {"phoneNumber": phone_number},
                "area": {
                    "areaType": "CIRCLE",
                    "center": {"latitude": lat, "longitude": lon},
                    "radius": radius
                }
            },
            "initialEvent": True,
            "subscriptionMaxEvents": 10,
            "subscriptionExpireTime": "2045-03-22T05:40:58.469Z"
        }
    }

    try:
        response = requests.post(
            url,
            data=json.dumps(payload),
            headers=HEADERS,
            verify=certifi.where(),
            timeout=15
        )
        print("📡 Create Subscription Response:", response.status_code, response.text)
        return response.json()
    except Exception as e:
        print("❌ Error creating geofence subscription:", e)
        return {"error": str(e)}

# Retrieve Single Geofencing Subscription

def retrieve_geofence_subscription(subscription_id: str):
    """
    Retrieve details of a specific geofence subscription.
    """
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions/{subscription_id}"

    try:
        response = requests.get(
            url,
            headers=HEADERS,
            verify=certifi.where(),
            timeout=15
        )
        print("📡 Retrieve Subscription Response:", response.status_code, response.text)
        return response.json()
    except Exception as e:
        print("❌ Error retrieving subscription:", e)
        return {"error": str(e)}

# Delete Geofencing Subscription

def delete_geofence_subscription(subscription_id: str):
    """
    Deletes an existing geofence subscription.
    """
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions/{subscription_id}"

    try:
        response = requests.delete(
            url,
            headers=HEADERS,
            verify=certifi.where(),
            timeout=15
        )
        print("🗑️ Delete Subscription Response:", response.status_code, response.text)
        return {"status": response.status_code, "response": response.text}
    except Exception as e:
        print("❌ Error deleting subscription:", e)
        return {"error": str(e)}

# List All Geofencing Subscriptions

def list_geofence_subscriptions():
    """
    Retrieve all active geofencing subscriptions.
    """
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions"

    try:
        response = requests.get(
            url,
            headers=HEADERS,
            verify=certifi.where(),
            timeout=15
        )
        print("📋 List Subscriptions Response:", response.status_code, response.text)
        return response.json()
    except Exception as e:
        print("❌ Error listing subscriptions:", e)
        return {"error": str(e)}

# Verify Device Location (already implemented)
def verify_location_nokia(phone_number: str, lat: float, lon: float, timestamp: str = None, radius: float = 50000) -> bool:
    """
    Verify a user's device location using Nokia Network-as-Code Location Verification API.
    """
    url = f"{NOKIA_BASE_URL}/location-verification/v1/verify"

    payload = {
        "device": {"phoneNumber": phone_number},
        "area": {
            "areaType": "CIRCLE",
            "center": {"latitude": lat, "longitude": lon},
            "radius": radius
        }
    }

    try:
        response = requests.post(
            url,
            data=json.dumps(payload),
            headers=HEADERS,
            verify=certifi.where(),
            timeout=15
        )
        print("📡 Nokia Verify Response:", response.status_code, response.text)

        if response.status_code == 200:
            data = response.json()
            result = data.get("verificationResult", "").upper()
            return result == "TRUE"
        else:
            return False
    except Exception as e:
        print("❌ Nokia API Error:", e)
        return False
