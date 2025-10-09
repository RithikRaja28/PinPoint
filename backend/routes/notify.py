import json
import requests
from google.oauth2 import service_account
import google.auth.transport.requests

# ----------------------------
# 🔧 CONFIGURATION
# ----------------------------
SERVICE_ACCOUNT_FILE = "serviceAccountKey.json"  # Path to your Firebase service account key
PROJECT_ID = "pinpoint-e02f5"                   # Your Firebase project ID
FCM_ENDPOINT = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"


# ----------------------------
# 🧩 ACCESS TOKEN GENERATOR
# ----------------------------
def get_access_token():
    """Generate OAuth2 access token from Firebase service account credentials."""
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=["https://www.googleapis.com/auth/firebase.messaging"]
    )
    request = google.auth.transport.requests.Request()
    credentials.refresh(request)
    return credentials.token


# ----------------------------
# 🚀 PUSH NOTIFICATION FUNCTION
# ----------------------------
def send_fcm_message(token, title, body, data=None, image_url=None):
    """Send push notification using FCM HTTP v1 API (with optional image)."""
    access_token = get_access_token()

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json; UTF-8"
    }

    # ✅ Notification payload
    notification_payload = {
        "title": title,
        "body": body
    }

    if image_url:
        notification_payload["image"] = image_url  # Add image if provided

    # ✅ Full message structure
    message = {
        "message": {
            "token": token,
            "notification": notification_payload,
            "data": data or {},  # Optional custom data payload
        }
    }

    # ✅ Send the request
    response = requests.post(FCM_ENDPOINT, headers=headers, data=json.dumps(message))

    print("📡 FCM Response:", response.status_code, response.text)
    return response.json()



    # send_fcm_message(
    #     DEVICE_FCM_TOKEN,
    #     "🔥 Dynamic Alert!",
    #     "Here’s an image just for you 👇",
    #     {"user_id": "123", "event": "custom_update"},
    #     image_url="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQMFUQWUr_5SKpmX24mZIWpQAYKj5iCJ9p7fA&s" 
    # )
