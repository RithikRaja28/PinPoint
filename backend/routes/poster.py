import os
from google import genai
from playwright.sync_api import sync_playwright
import base64
from flask import Blueprint, request, jsonify
import requests

poster = Blueprint("poster", __name__)

@poster.route("/poster", methods=["POST"])
def poster_create():
    # --- Gemini setup ---
    client = genai.Client(api_key="AIzaSyAsxQ2l6tnGZr9LUq7PbZaFgxp4Wm6Js5c")

    # --- Input details ---
    script_dir = os.path.dirname(os.path.abspath(__file__))
    logo_image_path = os.path.join(script_dir, "logos", "logo.png")

    # Convert local logo to base64 so it works in HTML
    with open(logo_image_path, "rb") as f:
        logo_base64 = base64.b64encode(f.read()).decode("utf-8")
    logo_data_url = f"data:image/png;base64,{logo_base64}"

    shop_name = "BlueMart"
    offer_details = "Get 50% OFF on all electronics this weekend!"
    shop_address = "123 Main Street, Downtown City"

    # --- Gemini prompt for stylish poster ---
    prompt = f"""
    Generate ONLY valid HTML with inline CSS (no markdown, no explanations).
    Create a bright, flashy, visually striking promotional poster webpage with the following:
    - Shop Logo: {logo_data_url}
    - Shop Name: {shop_name}
    - Offer Details: {offer_details}
    - Address: {shop_address}
    Design instructions:
    - Use a modern font like 'Poppins' or 'Montserrat'
    - Blue-themed gradient background with animated glow or shine
    - Center-aligned content inside a rounded, semi-transparent card
    - Large, bold text for the offer
    - Add smooth box-shadows and color transitions
    - Make it mobile-friendly and visually stunning
    Return ONLY the HTML code (no markdown, no explanations, no JSON).
    """

    # --- Generate HTML using Gemini ---
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[prompt]
    )

    html_code = response.text.strip()

    # --- Save HTML for future reference (optional) ---
    # html_file_path = os.path.join(script_dir, "poster.html")
    # with open(html_file_path, "w", encoding="utf-8") as f:
    #     f.write(html_code)

    # --- Render HTML and save as PNG ---
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1080, "height": 720})
        page.set_content(html_code, wait_until="load")
        page.screenshot(path="poster_screenshot.png", full_page=True)
        browser.close()

    print("📸 Stylish poster generated and saved as 'poster_screenshot.png'")
