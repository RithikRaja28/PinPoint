# blueprints/shop.py
from flask import Blueprint, request, jsonify, current_app
from database import db
from models.shop_model import ShopModel
from datetime import datetime
import os
import requests

shop_bp = Blueprint("shop", __name__)

# Optional: provider selection via env (GOOGLE_MAPS or MAPBOX or NOKIA)
MAP_PROVIDER = os.getenv("MAP_PROVIDER", "GOOGLE")  # "GOOGLE" | "MAPBOX" | "NOKIA"
MAPS_API_KEY = os.getenv("MAPS_API_KEY", "")

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
        payload = request.get_json(silent=True) or request.form.to_dict()
        name = payload.get("name")
        if not name:
            return jsonify({"error": "Shop name is required"}), 400

        shop = ShopModel(
            name=name,
            category=payload.get("category"),
            description=payload.get("description"),
            address_line=payload.get("address_line"),
            city=payload.get("city"),
            lat=float(payload.get("lat")) if payload.get("lat") else None,
            lon=float(payload.get("lon")) if payload.get("lon") else None,
            registration_no=payload.get("registration_no"),
            contact_number=payload.get("contact_number"),
            avg_spend=float(payload.get("avg_spend")) if payload.get("avg_spend") else None,
            has_offer=bool(payload.get("has_offer")) if payload.get("has_offer") else False,
            image_url=payload.get("image_url"),
            logo_url=payload.get("logo_url"),
        )

        db.session.add(shop)
        db.session.commit()

        return jsonify({"message": "Shop created", "shop": shop.to_dict()}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@shop_bp.route("/<int:shop_id>", methods=["GET"])
def get_shop(shop_id):
    shop = ShopModel.query.get_or_404(shop_id)
    return jsonify(shop.to_dict()), 200


# Simple proximity search (Haversine) — avoid for large scale; use PostGIS for production.
@shop_bp.route("/nearby", methods=["GET"])
def nearby_shops():
    """
    Query params: lat, lon (required), radius_meters (optional, default 1000), limit (optional)
    Returns shops within radius using Haversine formula in raw SQL.
    """
    try:
        lat = float(request.args.get("lat", None))
        lon = float(request.args.get("lon", None))
    except Exception:
        return jsonify({"error": "lat and lon query parameters required and must be numeric"}), 400

    radius_m = float(request.args.get("radius_m", 1000))
    limit = int(request.args.get("limit", 50))

    # Haversine in meters — earth radius 6371000
    haversine_sql = f"""
    SELECT id, name, category, address_line, city, state, postal_code, country, lat, lon,
      (6371000 * 2 * asin(sqrt(
        power(sin(radians((COALESCE(lat,0) - :lat)/2)),2) +
        cos(radians(:lat)) * cos(radians(COALESCE(lat,0))) *
        power(sin(radians((COALESCE(lon,0) - :lon)/2)),2)
      ))) AS distance_m
    FROM shops
    WHERE lat IS NOT NULL AND lon IS NOT NULL
    HAVING distance_m <= :radius_m
    ORDER BY distance_m ASC
    LIMIT :limit
    """

    # Use SQLAlchemy text() for raw query
    from sqlalchemy import text
    q = db.session.execute(text(haversine_sql), {"lat": lat, "lon": lon, "radius_m": radius_m, "limit": limit})
    rows = q.fetchall()
    results = []
    for r in rows:
        results.append({
            "id": r.id,
            "name": r.name,
            "category": r.category,
            "address_line": r.address_line,
            "city": r.city,
            "state": r.state,
            "postal_code": r.postal_code,
            "country": r.country,
            "lat": float(r.lat) if r.lat is not None else None,
            "lon": float(r.lon) if r.lon is not None else None,
            "distance_m": float(r.distance_m)
        })
    return jsonify({"count": len(results), "shops": results}), 200
