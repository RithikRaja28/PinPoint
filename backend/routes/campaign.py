from flask import Blueprint, request, jsonify
from database import db
from models.campaign_model import CampaignModel  # ✅ import the class
from datetime import datetime
import os

campaign_bp = Blueprint("campaign", __name__)
UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@campaign_bp.route("/", methods=["POST"])
def create_campaign():
    print("Creating campaign...")
    try:
        title = request.form.get("title")
        offer = request.form.get("offer")
        radius_km = request.form.get("radius_km")
        start = request.form.get("start")
        end = request.form.get("end")

        if not title or not offer or not radius_km or not start or not end:
            return jsonify({"error": "Missing required fields"}), 400

        # Convert types
        radius_km = float(radius_km)
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)

        # Poster
        poster_path = None
        if "poster" in request.files:
            poster_file = request.files["poster"]
            filename = f"{int(datetime.now().timestamp())}_{poster_file.filename}"
            save_path = os.path.join(UPLOAD_FOLDER, filename)
            poster_file.save(save_path)
            poster_path = save_path

        # Create campaign object
        campaign_obj = CampaignModel(
            title=title,
            offer=offer,
            radius_km=radius_km,
            start=start_dt,
            end=end_dt,
            poster_path=poster_path
        )
        print("Campaign object:", campaign_obj.__dict__)
        db.session.add(campaign_obj)
        try:
            db.session.commit()
            print("✅ Campaign saved in DB")
        except Exception as e:
            db.session.rollback()
            print("❌ DB Commit failed:", e)
            raise e

        return jsonify({
            "message": "Campaign created successfully",
            "campaign": campaign_obj.to_dict()
        }), 201

    except Exception as e:
        print("Error creating campaign:", e)
        return jsonify({"error": str(e)}), 500
