import os
from flask import Blueprint, request, jsonify, current_app
from database import db
from models.campaign_model import CampaignModel
from datetime import datetime

campaign_bp = Blueprint("campaign", __name__)

@campaign_bp.route("/", methods=["POST"])
def create_campaign():
    print("📢 Creating campaign...")
    try:
        title = request.form.get("title")
        offer = request.form.get("offer")
        radius_km = request.form.get("radius_km")
        start = request.form.get("start")
        end = request.form.get("end")
        owner_uid = None
        # prefer form value first (multipart) then JSON
        if request.form and request.form.get("owner_uid"):
            owner_uid = request.form.get("owner_uid")
        else:
            try:
                payload_json = request.get_json(silent=True) or {}
                owner_uid = payload_json.get("owner_uid") or owner_uid
            except Exception:
                pass

        if not title or not offer or not radius_km or not start or not end:
            return jsonify({"error": "Missing required fields"}), 400

        radius_km = float(radius_km)
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)

        upload_folder = current_app.config["UPLOAD_FOLDER"]
        os.makedirs(upload_folder, exist_ok=True)

        poster_path = None

        # 📁 Case 1: user uploads poster
        if "poster" in request.files:
            poster_file = request.files["poster"]
            filename = f"{int(datetime.now().timestamp())}_{poster_file.filename}"
            save_path = os.path.join(upload_folder, filename)
            poster_file.save(save_path)
            poster_path = f"/uploads/{filename}"

        # 📁 Case 2: AI-generated poster URL
        elif "poster_url" in request.form:
            poster_path = request.form.get("poster_url")

        # --- Save to DB ---
        campaign_obj = CampaignModel(
            owner_uid=owner_uid, 
            title=title,
            offer=offer,
            radius_km=radius_km,
            start=start_dt,
            end=end_dt,
            poster_path=poster_path
        )

        db.session.add(campaign_obj)
        db.session.commit()
        print("✅ Campaign saved in DB")

        return jsonify({
            "message": "Campaign created successfully",
            "campaign": campaign_obj.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        print("❌ Error creating campaign:", e)
        return jsonify({"error": str(e)}), 500
