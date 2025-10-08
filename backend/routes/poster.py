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
    try:
        # --- Campaign data from frontend ---
        title = request.form.get("title", "My Campaign")
        offer = request.form.get("offer", "Special Offer!")
        shop_name = request.form.get("shop_name", "My Shop")
        shop_address = request.form.get("shop_address", "123 Street")
        radius_km = float(request.form.get("radius_km", 5))
        start = request.form.get("start")
        end = request.form.get("end")

        if not start or not end:
            return jsonify({"error": "Missing start or end date"}), 400

        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)

        # --- Handle optional logo upload ---
        logo_data_url = ""
        if "logo" in request.files:
            logo_file = request.files["logo"]
            filename = f"logo_{int(datetime.now().timestamp())}.png"
            logo_path = os.path.join(current_app.config["UPLOAD_FOLDER"], filename)
            logo_file.save(logo_path)
            with open(logo_path, "rb") as f:
                logo_base64 = base64.b64encode(f.read()).decode("utf-8")
            logo_data_url = f"data:image/png;base64,{logo_base64}"

        # --- Generate HTML for poster ---
        prompt_html = f"""
            <html>
            <head>
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

        # --- Render HTML → PNG poster ---
        poster_filename = f"poster_{int(datetime.now().timestamp())}.png"
        poster_path = os.path.join(current_app.config["UPLOAD_FOLDER"], poster_filename)

        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1080, "height": 720})
            page.set_content(prompt_html, wait_until="load")
            page.screenshot(path=poster_path, full_page=True)
            browser.close()

        # ✅ Wait to ensure file is written to disk
        time.sleep(2)
        if not os.path.exists(poster_path):
            return jsonify({"error": "Poster not found after generation"}), 500

        poster_url = f"/uploads/{poster_filename}"

        # --- Save campaign to DB with poster ---
        campaign_obj = CampaignModel(
            title=title,
            offer=offer,
            radius_km=radius_km,
            start=start_dt,
            end=end_dt,
            poster_path=poster_url
        )
        db.session.add(campaign_obj)
        db.session.commit()

        return jsonify({
            "message": "✅ Campaign created with AI poster",
            "poster_url": poster_url,
            "campaign": campaign_obj.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        print("❌ Error generating poster:", e)
        return jsonify({"error": str(e)}), 500
