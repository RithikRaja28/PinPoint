# import json
# import requests
# from google.oauth2 import service_account
# import google.auth.transport.requests

# # ----------------------------
# # 🔧 CONFIGURATION
# # ----------------------------
# SERVICE_ACCOUNT_FILE = "serviceAccountKey.json"  # Path to your Firebase service account key
# PROJECT_ID = "pinpoint-e02f5"                   # Your Firebase project ID
# FCM_ENDPOINT = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"


# # ----------------------------
# # 🧩 ACCESS TOKEN GENERATOR
# # ----------------------------
# def get_access_token():
#     """Generate OAuth2 access token from Firebase service account credentials."""
#     credentials = service_account.Credentials.from_service_account_file(
#         SERVICE_ACCOUNT_FILE,
#         scopes=["https://www.googleapis.com/auth/firebase.messaging"]
#     )
#     request = google.auth.transport.requests.Request()
#     credentials.refresh(request)
#     return credentials.token


# # ----------------------------
# # 🚀 PUSH NOTIFICATION FUNCTION
# # ----------------------------
# def send_fcm_message(token, title, body, data=None, image_url=None):
#     """Send push notification using FCM HTTP v1 API (with optional image)."""
#     access_token = get_access_token()

#     headers = {
#         "Authorization": f"Bearer {access_token}",
#         "Content-Type": "application/json; UTF-8"
#     }

#     # ✅ Notification payload
#     notification_payload = {
#         "title": title,
#         "body": body
#     }

#     if image_url:
#         notification_payload["image"] = image_url  # Add image if provided

#     # ✅ Full message structure
#     message = {
#         "message": {
#             "token": token,
#             "notification": notification_payload,
#             "data": data or {},  # Optional custom data payload
#         }
#     }

#     # ✅ Send the request
#     response = requests.post(FCM_ENDPOINT, headers=headers, data=json.dumps(message))

#     print("📡 FCM Response:", response.status_code, response.text)
#     return response.json()


# def send_notify(phone_no):


#     send_fcm_message(
#         DEVICE_FCM_TOKEN,
#         "🔥 Dynamic Alert!",
#         "Here’s an image just for you 👇",
#         {"user_id": "123", "event": "custom_update"},
#         image_url="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQMFUQWUr_5SKpmX24mZIWpQAYKj5iCJ9p7fA&s" 
#     )


import json
import requests
from google.oauth2 import service_account
import google.auth.transport.requests
import firebase_admin
from firebase_admin import credentials, firestore

# ----------------------------
# 🔧 CONFIGURATION
# ----------------------------
SERVICE_ACCOUNT_FILE = "serviceAccountKey.json"  # Path to Firebase service account key
PROJECT_ID = "pinpoint-e02f5"                   # Your Firebase project ID
FCM_ENDPOINT = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"

# ----------------------------
# 🔥 Initialize Firestore
# ----------------------------
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)
    firebase_admin.initialize_app(cred)

db = firestore.client()


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

    notification_payload = {
        "title": title,
        "body": body
    }

    if image_url:
        notification_payload["image"] = image_url

    message = {
        "message": {
            "token": token,
            "notification": notification_payload,
            "data": data or {},
        }
    }

    response = requests.post(FCM_ENDPOINT, headers=headers, data=json.dumps(message))
    print("📡 FCM Response:", response.status_code, response.text)
    return response.json()


# ----------------------------
# 🔔 FIRESTORE → NOTIFY FUNCTION
# ----------------------------
def send_notify(phone_no, title, imageurl):
    """Fetch FCM token for the phone number and send notification."""
    try:
        # 🔹 Retrieve the token from Firestore
        doc_ref = db.collection("fcm_map").document(phone_no)
        doc = doc_ref.get()

        if not doc.exists:
            print(f"❌ No FCM token found for {phone_no}")
            return {"success": False, "error": "Token not found"}

        fcm_token = doc.to_dict().get("token")

        if not fcm_token:
            print(f"⚠️ Document found but token field is missing for {phone_no}")
            return {"success": False, "error": "Token missing"}

        print(f"✅ FCM token retrieved for {phone_no}: {fcm_token}")

        # 🔹 Send the push notification
        response = send_fcm_message(
            fcm_token,
            title,
            "Here’s an image just for you 👇",
            {"user_id": "123", "event": "custom_update"},
            image_url=imageurl
        )

        return {"success": True, "response": response}

    except Exception as e:
        print(f"❌ Error sending notification: {e}")
        return {"success": False, "error": str(e)}


# ----------------------------
# 🧪 TEST CALL
