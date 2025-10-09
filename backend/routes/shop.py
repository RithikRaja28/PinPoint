# blueprints/shop.py
from flask import Blueprint, request, jsonify, current_app,url_for
from database import db
from models.shop_model import ShopModel
from datetime import datetime
import os
import requests
import uuid,time
from sqlalchemy import text
from sqlalchemy.exc import ProgrammingError
import random
import math
from werkzeug.utils import secure_filename


shop_bp = Blueprint("shop", __name__)

# Optional: provider selection via env (GOOGLE_MAPS or MAPBOX or NOKIA)
MAP_PROVIDER = os.getenv("MAP_PROVIDER", "GOOGLE")  # "GOOGLE" | "MAPBOX" | "NOKIA"
MAPS_API_KEY = os.getenv("MAPS_API_KEY", "")

ALLOWED_IMAGE_EXT = {"png", "jpg", "jpeg", "gif", "webp"}

def _allowed_file(filename):
    if not filename:
        return False
    ext = filename.rsplit(".", 1)[-1].lower()
    return ext in ALLOWED_IMAGE_EXT

def _save_upload(file_storage, subfolder=""):
    """
    Save a werkzeug FileStorage to UPLOAD_FOLDER and return the public URL path.
    Returns the final filename (relative) or None on failure.
    """
    if file_storage is None or file_storage.filename == "":
        return None

    if not _allowed_file(file_storage.filename):
        current_app.logger.warning("Rejected file with disallowed extension: %s", file_storage.filename)
        return None

    uploads_dir = current_app.config.get("UPLOAD_FOLDER", "uploads")
    # optionally create subfolder under uploads
    target_dir = os.path.join(uploads_dir, subfolder) if subfolder else uploads_dir
    os.makedirs(target_dir, exist_ok=True)

    filename = secure_filename(file_storage.filename)
    # prefix with timestamp + uuid to avoid collisions
    prefix = f"{int(time.time())}-{uuid.uuid4().hex[:8]}"
    final_name = f"{prefix}-{filename}"
    final_path = os.path.join(target_dir, final_name)
    try:
        file_storage.save(final_path)
    except Exception as e:
        current_app.logger.exception("Failed to save uploaded file: %s", e)
        return None

    # Build a public URL to the uploads route. Using request.host_url + /uploads/<filename>
    # If you used subfolders, include them in URL.
    rel_path = os.path.join(subfolder, final_name) if subfolder else final_name
    # request.host_url already ends with '/', so rstrip
    public_url = f"/uploads/{rel_path.replace(os.path.sep, '/')}"
    return public_url   


def geocode_address(address):
    """
    Call configured geocode provider to get lat/lon for an address.
    Returns (lat, lon) or (None, None) on failure.
    NOTE: Keep calls rate-limited and cache results in prod.
    """
    if not MAPS_API_KEY:
        return (None, None)

    try:
        if MAP_PROVIDER.upper() == "GOOGLE":
            url = "https://maps.googleapis.com/maps/api/geocode/json"
            params = {"address": address, "key": MAPS_API_KEY}
            r = requests.get(url, params=params, timeout=5)
            j = r.json()
            if j.get("results"):
                loc = j["results"][0]["geometry"]["location"]
                return (loc["lat"], loc["lng"])
        elif MAP_PROVIDER.upper() == "MAPBOX":
            url = f"https://api.mapbox.com/geocoding/v5/mapbox.places/{requests.utils.requote_uri(address)}.json"
            params = {"access_token": MAPS_API_KEY, "limit": 1}
            r = requests.get(url, params=params, timeout=5)
            j = r.json()
            if j.get("features"):
                coords = j["features"][0]["center"]  # [lon, lat]
                return (coords[1], coords[0])
        elif MAP_PROVIDER.upper() == "NOKIA":
            # Placeholder for Nokia/GEO API — implement according to Nokia docs
            return (None, None)
    except Exception as e:
        current_app.logger.warning("Geocode failed: %s", e)
    return (None, None)


@shop_bp.route("/", methods=["POST"])
def create_shop():
    try:
        # Prefer form data for multipart/form-data (files + fields)
        if request.content_type and request.content_type.startswith("application/json"):
            # If client sent JSON, this still works
            payload = request.get_json(silent=True) or {}
        else:
            payload = request.form.to_dict() or {}

        name = payload.get("name")
        if not name:
            return jsonify({"error": "Shop name is required"}), 400

        # Handle uploaded files (image, logo)
        image_url = None
        logo_url = None

        # 'image' and 'logo' are the field names your Flutter code uses
        if 'image' in request.files:
            image_file = request.files.get('image')
            saved = _save_upload(image_file)
            if saved:
                image_url = saved

        if 'logo' in request.files:
            logo_file = request.files.get('logo')
            saved = _save_upload(logo_file)
            if saved:
                logo_url = saved

        # Allow clients to optionally pass direct image_url/logo_url as fallback
        if not image_url and payload.get("image_url"):
            image_url = payload.get("image_url")
        if not logo_url and payload.get("logo_url"):
            logo_url = payload.get("logo_url")

        shop = ShopModel(
            name=name,
            owner_uid=payload.get("owner_uid"),
            category=payload.get("category"),
            description=payload.get("description"),
            address_line=payload.get("address_line"),
            city=payload.get("city"),
            lat=float(payload.get("lat")) if payload.get("lat") else None,
            lon=float(payload.get("lon")) if payload.get("lon") else None,
            registration_no=payload.get("registration_no"),
            contact_number=payload.get("contact_number"),
            avg_spend=float(payload.get("avg_spend")) if payload.get("avg_spend") else None,
            has_offer=(payload.get("has_offer") in ("1", "true", "True", True)) if payload.get("has_offer") else False,
            image_url=image_url,
            logo_url=logo_url,
        )

        db.session.add(shop)
        db.session.commit()

        return jsonify({"message": "Shop created", "shop": shop.to_dict()}), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.exception("Failed to create shop: %s", e)
        return jsonify({"error": str(e)}), 500

@shop_bp.route("/test", methods=["GET"])
def test():
    return "Working!"

@shop_bp.route("/<int:shop_id>", methods=["GET"])
def get_shop(shop_id):
    shop = ShopModel.query.get_or_404(shop_id)
    return jsonify(shop.to_dict()), 200



@shop_bp.route("/nearby", methods=["GET"])
def nearby_shops():
    """
    Query params:
      lat (required), lon (required),
      radius_meters (optional, default 10000),  -- we default to 10km as requested
      limit (optional, default 50)

    Returns shops ordered by distance (nearest first) up to radius, plus
    hasOffer flag if owner_uid has an active campaign.
    """
    try:
        lat = float(request.args.get("lat", None))
        lon = float(request.args.get("lon", None))
    except Exception:
        return jsonify({"error": "lat and lon query parameters required and must be numeric"}), 400

    # default to 10 km (10000 m)
    try:
        radius_m = float(request.args.get("radius_m", 10000))
    except Exception:
        radius_m = 10000.0

    # cap radius to 10 km (safeguard) — you may remove this cap if not desired
    if radius_m > 10000:
        radius_m = 10000.0

    try:
        limit = int(request.args.get("limit", 50))
    except Exception:
        limit = 50

    # Prefer PostGIS: use ST_DWithin + ST_Distance for accurate ordering
    # ST_MakePoint expects (lon, lat)
    postgis_sql = """
    SELECT
      s.id,
      s.name,
      s.category,
      s.description,
      s.address_line,
      s.city,
      s.lat,
      s.lon,
      s.avg_spend,
      s.image_url,
      -- distance in meters using geography
      ST_Distance(
        ST_SetSRID(ST_MakePoint(COALESCE(s.lon,0), COALESCE(s.lat,0)), 4326)::geography,
        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
      ) AS distance_m,
      -- whether there exists an active campaign owned by this shop owner
      EXISTS (
        SELECT 1 FROM campaigns c
        WHERE c.owner_uid IS NOT NULL
          AND c.owner_uid = s.owner_uid
          AND c.start <= now() AT TIME ZONE 'utc'
          AND c.end >= now() AT TIME ZONE 'utc'
      ) AS has_offer
    FROM shops s
    WHERE s.lat IS NOT NULL AND s.lon IS NOT NULL
      AND ST_DWithin(
        ST_SetSRID(ST_MakePoint(COALESCE(s.lon,0), COALESCE(s.lat,0)), 4326)::geography,
        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
        :radius_m
      )
    ORDER BY distance_m ASC
    LIMIT :limit
    """

    try:
        q = db.session.execute(
            text(postgis_sql),
            {"lat": lat, "lon": lon, "radius_m": radius_m, "limit": limit},
        )
        rows = q.fetchall()
    except ProgrammingError as pe:
        # PostGIS functions missing (or syntax error). Fall back to Haversine SQL.
        current_app.logger.warning("PostGIS query failed, falling back to Haversine: %s", pe)

        # Haversine (meters) — earth radius 6371000
        haversine_sql = """
        SELECT
          s.id,
          s.name,
          s.category,
          s.description,
          s.address_line,
          s.city,
          s.lat,
          s.lon,
          s.avg_spend,
          s.image_url,
          (6371000 * 2 * asin(sqrt(
            power(sin(radians((COALESCE(s.lat,0) - :lat)/2)),2) +
            cos(radians(:lat)) * cos(radians(COALESCE(s.lat,0))) *
            power(sin(radians((COALESCE(s.lon,0) - :lon)/2)),2)
          ))) AS distance_m,
          EXISTS (
            SELECT 1 FROM campaigns c
            WHERE c.owner_uid IS NOT NULL
              AND c.owner_uid = s.owner_uid
              AND c.start <= now() AT TIME ZONE 'utc'
              AND c.end >= now() AT TIME ZONE 'utc'
          ) AS has_offer
        FROM shops s
        WHERE s.lat IS NOT NULL AND s.lon IS NOT NULL
        HAVING distance_m <= :radius_m
        ORDER BY distance_m ASC
        LIMIT :limit
        """
        q = db.session.execute(
            text(haversine_sql),
            {"lat": lat, "lon": lon, "radius_m": radius_m, "limit": limit},
        )
        rows = q.fetchall()
    except Exception as e:
        current_app.logger.exception("Error running nearby query: %s", e)
        return jsonify({"error": "Internal server error"}), 500

    # Build response — match frontend Shop model
    results = []
    for r in rows:
        # rows may be sqlalchemy RowProxy — access by column name
        # handle missing columns gracefully
        sid = getattr(r, "id", None)
        name = getattr(r, "name", None)
        category = getattr(r, "category", None)
        lat_val = getattr(r, "lat", None)
        lon_val = getattr(r, "lon", None)
        avg_spend = getattr(r, "avg_spend", None)
        image_url = getattr(r, "image_url", None)
        description = getattr(r, "description", None) or ""
        distance_m = getattr(r, "distance_m", None)
        has_offer = getattr(r, "has_offer", False)

        # normalize numeric types
        try:
            distance_m_f = float(distance_m) if distance_m is not None else None
        except Exception:
            distance_m_f = None

        try:
            avg_spend_f = float(avg_spend) if avg_spend is not None else None
        except Exception:
            avg_spend_f = None

        # Randomize rating (between 3.5 and 5.0, one decimal)
        rating = round(random.uniform(3.5, 5.0), 1)

        results.append({
            "id": sid,
            "name": name,
            "category": category,
            "lat": float(lat_val) if lat_val is not None else None,
            "lon": float(lon_val) if lon_val is not None else None,
            "avgSpend": avg_spend_f,
            "hasOffer": bool(has_offer),
            "distanceMeters": distance_m_f,
            "snippet": description,      # frontend expects snippet -> use description
            "imageUrl": image_url,
            "rating": rating,
        })

    return jsonify({"count": len(results), "shops": results}), 200