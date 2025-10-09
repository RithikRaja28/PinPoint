import requests
import urllib.parse
import os



# ------------------------------
# 🔧 CONFIGURATION
# ------------------------------
NAC_CLIENT_CREDENTIALS_URL = "https://network-as-code.p-eu.rapidapi.com/oauth2/v1/auth/clientcredentials"
WELL_KNOWN_METADATA_URL = "https://network-as-code.p-eu.rapidapi.com/.well-known/openid-configuration"
NUMBER_VERIFICATION_URL = "https://network-as-code.p-eu.rapidapi.com/passthrough/camara/v1/number-verification/number-verification/v0/verify"
RAPIDAPIHOST = "network-as-code.nokia.rapidapi.com"
REDIRECT_URI = "https://teammosambi.requestcatcher.com/"  # Replace with your RequestCatcher URL

PHONE_NUMBER = "99999991001" 
RAPIDAPI_KEY = "026086a8f0msh74fcf7cb83ef534p1bd1e2jsnd9a723138bc6"  # Replace with your real key

# Globals
CLIENT_ID = None
CLIENT_SECRET = None
AUTH_ENDPOINT = None
TOKEN_ENDPOINT = None
AUTH_CODE = None
ACCESS_TOKEN = None

# ------------------------------
# 🪙 Step 1: Get Client Credentials
# ------------------------------
def get_client_credentials():
    headers = {
        "content-type": "application/json",
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": RAPIDAPIHOST,
    }

    response = requests.get(NAC_CLIENT_CREDENTIALS_URL, headers=headers)
    if response.status_code != 200:
        raise Exception("Error getting client credentials")

    credentials = response.json()
    print("Client Credentials:", credentials)
    return credentials["client_id"], credentials["client_secret"]


# ------------------------------
# 🔗 Step 2: Get Authorization + Token Endpoints
# ------------------------------
def get_endpoints():
    headers = {
        "content-type": "application/json",
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": RAPIDAPIHOST,
    }

    response = requests.get(WELL_KNOWN_METADATA_URL, headers=headers)
    if response.status_code != 200:
        raise Exception("Error getting endpoints")

    endpoints = response.json()
    print("OIDC Metadata:", endpoints)
    return endpoints["authorization_endpoint"], endpoints["token_endpoint"]


# ------------------------------
# 🔐 Step 3: Get Authorization Code
# ------------------------------
def get_authorization_code():
    auth_code_url = (
        f"{AUTH_ENDPOINT}?scope=number-verification:verify"
        f"&response_type=code"
        f"&client_id={CLIENT_ID}"
        f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
        f"&state=App-state"
        f"&login_hint=%2B{PHONE_NUMBER}"
    )

    print("Auth Code URL:", auth_code_url)

    response = requests.get(auth_code_url, allow_redirects=True)
    final_url = response.url

    parsed_url = urllib.parse.urlparse(final_url)
    query_params = urllib.parse.parse_qs(parsed_url.query)
    code = query_params.get("code", [None])[0]

    if not code:
        raise Exception("Authorization code not received")

    print("Authorization code:", code)
    return code


# ------------------------------
# 🪙 Step 4: Get Access Token
# ------------------------------
def get_access_token():
    data = {
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "grant_type": "authorization_code",
        "code": AUTH_CODE,
    }

    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    response = requests.post(TOKEN_ENDPOINT, data=data, headers=headers)

    if response.status_code != 200:
        raise Exception("Error getting Access Token")

    access_token = response.json().get("access_token")
    if not access_token:
        raise Exception("Access token not received")

    print("Access Token:", access_token)
    return access_token


def verify_phone_number():
    headers = {
        "content-type": "application/json",
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": RAPIDAPIHOST,
        "Authorization": f"Bearer {ACCESS_TOKEN}",
    }

    data = {"phoneNumber": f"+{PHONE_NUMBER}"}
    response = requests.post(NUMBER_VERIFICATION_URL, json=data, headers=headers)

    print("Verification Response:", response.status_code, response.text)

    if response.status_code != 200:
        raise Exception("Error verifying phone number")

    result = response.json()
    if result.get("devicePhoneNumberVerified"):
        print("✅ Number verification successful!")
        return True
    else:
        print("❌ Number verification unsuccessful!")
        return False


# ------------------------------
# 🚀 Main Execution Flow
# ------------------------------

def verify_number(phone_number,redirect_url):
    try:
        print("Getting client credentials...")
        CLIENT_ID, CLIENT_SECRET = get_client_credentials()

        print("Getting authorization and token endpoints...")
        AUTH_ENDPOINT, TOKEN_ENDPOINT = get_endpoints()

        print("Getting authorization code...")
        AUTH_CODE = get_authorization_code()

        print("Getting access token...")
        ACCESS_TOKEN = get_access_token()

        print("Verifying the number...")
        return verify_phone_number()

    except Exception as e:
        print("❌ Error:", e)
