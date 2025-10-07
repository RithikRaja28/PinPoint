import os
from flask import Blueprint, request, jsonify
from google import genai
from playwright.sync_api import sync_playwright
from datetime import datetime
import base64

poster_bp = Blueprint("poster", __name__)

UPLOAD_DIR = os.path.join(os.getcwd(), "uploads", "logos")
os.makedirs(UPLOAD_DIR, exist_ok=True)

@poster_bp.route("/poster", methods=["POST"])
def poster_create():
    try:
        print("Generating poster...")
        api_key = os.getenv("GEMINI_API_KEY")
        client = genai.Client(api_key=api_key)

        # --- Get campaign data ---
        shop_name = request.form.get("shop_name", "My Shop")
        offer_details = request.form.get("offer_details", "Special Offer!")
        shop_address = request.form.get("shop_address", "123 Street")

        # --- Handle uploaded logo ---
        logo_data_url = ""
        if "logo" in request.files:
            logo_file = request.files["logo"]
            filename = f"logo_{int(datetime.now().timestamp())}.png"
            logo_path = os.path.join(UPLOAD_DIR, filename)
            logo_file.save(logo_path)

            with open(logo_path, "rb") as f:
                logo_base64 = base64.b64encode(f.read()).decode("utf-8")
            logo_data_url = f"data:image/png;base64,{logo_base64}"

        # --- Gemini Prompt ---
        prompt = f"""
        Generate ONLY valid HTML with inline CSS (no markdown).
        Create a visually stunning promotional poster with:
        - Shop Name: {shop_name}
        - Offer: {offer_details}
        - Address: {shop_address}
        - Logo: {logo_data_url if logo_data_url else "No logo"}
        Styling:
        - Gradient background, glowing animation
        - Bold modern typography
        - Responsive, center-aligned layout
        """

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[prompt]
        )

        html_code = response.text.strip()

        # --- Render poster screenshot ---
        poster_filename = f"poster_{int(datetime.now().timestamp())}.png"
        poster_path = os.path.join("uploads", poster_filename)

        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1080, "height": 720})
            page.set_content(html_code, wait_until="load")
            page.screenshot(path=poster_path, full_page=True)
            browser.close()

        return jsonify({
            "message": "Poster generated successfully!",
            "poster_url": f"/uploads/{poster_filename}"
        }), 200

    except Exception as e:
        print("Error:", e)
        return jsonify({"error": str(e)}), 500  


