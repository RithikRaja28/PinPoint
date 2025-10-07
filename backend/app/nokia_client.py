import os
import json
import requests
import certifi

NOKIA_BASE_URL = os.getenv("NOKIA_BASE_URL", "https://network-as-code.p-eu.rapidapi.com")
NOKIA_RAPIDAPI_KEY = os.getenv("NOKIA_RAPIDAPI_KEY")
NOKIA_RAPIDAPI_HOST = os.getenv("NOKIA_RAPIDAPI_HOST", "network-as-code.nokia.rapidapi.com")


def verify_location_nokia(
    phone_number: str,
    lat: float,
    lon: float,
    timestamp: str = None,
    radius: float = 50000
) -> bool:
    """
    Verify a user's device location using Nokia Network-as-Code Location Verification API.

    Args:
        phone_number (str): User's mobile number in international format (+CountryCodeNumber)
        lat (float): Latitude of the geofence center
        lon (float): Longitude of the geofence center
        timestamp (str): Optional timestamp (for logging or auditing)
        radius (float): Radius of the geofence area in meters

    Returns:
        bool: True if device is within the specified area, False otherwise
    """

    url = f"{NOKIA_BASE_URL}/location-verification/v1/verify"

    headers = {
        "x-rapidapi-key": NOKIA_RAPIDAPI_KEY,
        "x-rapidapi-host": NOKIA_RAPIDAPI_HOST,
        "Content-Type": "application/json"
    }

    payload = {
        "device": {"phoneNumber": phone_number},
        "area": {
            "areaType": "CIRCLE",
            "center": {"latitude": lat, "longitude": lon},
            "radius": radius
        }
    }

    print("📡 Sending request to Nokia API:", url)
    print("📦 Payload:", json.dumps(payload))

    try:
        response = requests.post(
            url,
            data=json.dumps(payload),
            headers=headers,
            verify=certifi.where(),
            timeout=15
        )

        print("📡 Nokia API Response:", response.status_code, response.text)

        if response.status_code == 200:
            data = response.json()
            result = data.get("verificationResult", "").upper()
            return result == "TRUE"
        else:
            print("❌ Nokia API returned non-200 response.")
            return False

    except Exception as e:
        print("❌ Nokia API Error:", e)
        return False
