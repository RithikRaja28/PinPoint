import os
import time
import base64
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
from playwright.sync_api import sync_playwright
from database import db
from models.campaign_model import CampaignModel

poster_bp = Blueprint("poster_bp", __name__)

@poster_bp.route("/poster", methods=["POST"])
def poster_create():
    print("🚀 Generating poster...")
    """
    Generate a poster PNG from HTML (Playwright), save to uploads folder,
    and return the poster_url to the frontend. Do NOT save campaign to DB.
    """
    try:
        # --- Campaign data from frontend (for poster text only) ---
        title = request.form.get("title", "My Campaign")
        offer = request.form.get("offer", "Special Offer!")
        shop_name = request.form.get("shop_name", "My Shop")
        shop_address = request.form.get("shop_address", "123 Street")
        try:
            radius_km = float(request.form.get("radius_km", 5))
        except Exception:
            radius_km = 5.0
        start = request.form.get("start")
        end = request.form.get("end")

        if not start or not end:
            return jsonify({"error": "Missing start or end date"}), 400

        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)

        # --- Handle optional logo upload: convert to data URL for embedding ---
        logo_data_url = ""
        if "logo" in request.files:
            logo_file = request.files["logo"]
            # create safe unique filename
            filename = f"logo_{int(datetime.now().timestamp())}_{logo_file.filename}"
            logo_path = os.path.join(current_app.config["UPLOAD_FOLDER"], filename)
            os.makedirs(current_app.config["UPLOAD_FOLDER"], exist_ok=True)
            logo_file.save(logo_path)
            # encode as base64 data url for inline <img src="data:...">
            with open(logo_path, "rb") as f:
                logo_base64 = base64.b64encode(f.read()).decode("utf-8")
            # try to detect mime from extension, default to png
            ext = os.path.splitext(filename)[1].lower()
            mime = "image/png"
            if ext in (".jpg", ".jpeg"):
                mime = "image/jpeg"
            elif ext == ".gif":
                mime = "image/gif"
            logo_data_url = f"data:{mime};base64,{logo_base64}"

        # --- Generate HTML for poster ---
        prompt_html = f"""
            <html>
            <head>
            <meta charset="utf-8" />
            <style>
                body {{
                    margin: 0;
                    padding: 0;
                    width: 1080px;
                    height: 720px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-family: 'Segoe UI', Arial, sans-serif;
                    background: linear-gradient(
                        rgba(0, 0, 0, 0.5), 
                        rgba(0, 0, 0, 0.5)
                    ), 
                    url('https://images.unsplash.com/photo-1556742400-b5d8d80d48f7?auto=format&fit=crop&w=1080&q=80');
                    background-size: cover;
                    background-position: center;
                    color: #fff;
                }}
                .poster {{
                    text-align: center;
                    background: rgba(255, 255, 255, 0.08);
                    padding: 50px;
                    border-radius: 20px;
                    backdrop-filter: blur(8px);
                    box-shadow: 0px 8px 30px rgba(0,0,0,0.4);
                    max-width: 800px;
                    width: 90%;
                }}
                .logo {{
                    position: absolute;
                    top: 40px;
                    right: 40px;
                    background: rgba(255,255,255,0.9);
                    padding: 8px 12px;
                    border-radius: 12px;
                }}
                .logo img {{
                    width: 100px;
                    height: auto;
                    border-radius: 10px;
                }}
                h1 {{
                    font-size: 70px;
                    margin: 0;
                    letter-spacing: 2px;
                    color: #ffd700;
                    text-transform: uppercase;
                    text-shadow: 3px 3px 6px rgba(0,0,0,0.5);
                }}
                h2 {{
                    font-size: 42px;
                    margin: 20px 0;
                    color: #ffffff;
                    font-weight: 400;
                }}
                p {{
                    font-size: 26px;
                    margin: 15px 0;
                }}
                .cta {{
                    margin-top: 40px;
                    display: inline-block;
                    padding: 15px 40px;
                    background: linear-gradient(to right, #ff8c00, #ff2e63);
                    border-radius: 50px;
                    font-size: 28px;
                    font-weight: bold;
                    color: #fff;
                    text-transform: uppercase;
                    box-shadow: 0px 5px 20px rgba(255, 46, 99, 0.5);
                }}
            </style>
            </head>
            <body>
                <div class="poster">
                    <h1>{offer}</h1>
                    <h2>at {shop_name}</h2>
                    <p>📍 {shop_address}</p>
                    <p>📅 {start_dt.strftime('%b %d, %Y')} - {end_dt.strftime('%b %d, %Y')}</p>
                    <div class="cta">Visit Us Today!</div>
                </div>
                {f'<div class="logo"><img src="{logo_data_url}" /></div>' if logo_data_url else ''}
            </body>
            </html>
            """

        # --- Render HTML → PNG poster using Playwright ---
        poster_filename = f"poster_{int(datetime.now().timestamp())}.png"
        poster_path = os.path.join(current_app.config["UPLOAD_FOLDER"], poster_filename)
        os.makedirs(current_app.config["UPLOAD_FOLDER"], exist_ok=True)

        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1080, "height": 720})
            page.set_content(prompt_html, wait_until="load")
            page.screenshot(path=poster_path, full_page=True)
            browser.close()

        # small sleep to ensure file appears on disk
        time.sleep(0.2)
        if not os.path.exists(poster_path):
            return jsonify({"error": "Poster not found after generation"}), 500

        poster_url = f"/uploads/{poster_filename}"

        # --- Return only poster url, do NOT save to DB ---
        return jsonify({
            "message": "Poster generated",
            "poster_url": poster_url
        }), 201

    except Exception as e:
        # keep error details in server logs but return safe message
        current_app.logger.exception("❌ Error generating poster: %s", e)
        db.session.rollback() if 'db' in globals() else None
        return jsonify({"error": str(e)}), 500
