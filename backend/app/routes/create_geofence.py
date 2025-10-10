import os
import json
import requests
import certifi

NOKIA_BASE_URL = os.getenv("NOKIA_BASE_URL", "https://network-as-code.p-eu.rapidapi.com")
NOKIA_RAPIDAPI_KEY = os.getenv("NOKIA_RAPIDAPI_KEY","026086a8f0msh74fcf7cb83ef534p1bd1e2jsnd9a723138bc6")
NOKIA_RAPIDAPI_HOST = os.getenv("NOKIA_RAPIDAPI_HOST", "network-as-code.nokia.rapidapi.com")

HEADERS = {
    "x-rapidapi-key": NOKIA_RAPIDAPI_KEY,
    "x-rapidapi-host": NOKIA_RAPIDAPI_HOST,
    "Content-Type": "application/json"
}
HEADERS = {
    "Content-Type": "application/json",
    "X-RapidAPI-Key": NOKIA_RAPIDAPI_KEY,
    "X-RapidAPI-Host": NOKIA_RAPIDAPI_HOST
}

def create_geofence_subscription(phone_number: str, lat: float, lon: float, radius: int = 2000):
    url = f"{NOKIA_BASE_URL}/geofencing-subscriptions/v0.3/subscriptions"
    payload = {
        "protocol": "HTTP",
        "sink": "http://192.168.1.11:5000/api/geofence/callback",  
        "types": ["org.camaraproject.geofencing-subscriptions.v0.area-left"], 
        "config": {
            "subscriptionDetail": {
                "device": {"phoneNumber": phone_number},
                "area": {
                    "areaType": "CIRCLE",
                    "center": {"latitude": lat, "longitude": lon},
                    "radius": radius
                }
            },
            "initialEvent": True,  # optional, triggers once immediately after creation
            "subscriptionMaxEvents": 10,
            "subscriptionExpireTime": "2045-03-22T05:40:58.469Z"
        }
    }

    try:
        res = requests.post(url, data=json.dumps(payload),
                            headers=HEADERS, verify=certifi.where(), timeout=15)
        print("📡 Create Geofence Response:", res.status_code, res.text)
        return res.json()
    except Exception as e:
        print("❌ Error creating geofence subscription:", e)
        return {"error": str(e)}



create_geofence_subscription("+36719991000", 28.5552, 77.0482,  2000)