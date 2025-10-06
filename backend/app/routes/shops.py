from flask import Blueprint, request, jsonify
from app.db import db
from app.models import Shop, User
from geoalchemy2.shape import from_shape
from shapely.geometry import Point

shops_bp = Blueprint("shops", __name__)

@shops_bp.route("/create", methods=["POST"])
def create_shop():
    payload = request.json
    owner_id = payload.get("owner_id")
    name = payload.get("name")
    address = payload.get("address")
    lat = payload.get("lat")
    lon = payload.get("lon")

    if not all([owner_id, name, lat, lon]):
        return jsonify({"error": "missing fields"}), 400

    # convert lat/lon to PostGIS point
    point = from_shape(Point(float(lon), float(lat)), srid=4326)

    shop = Shop(owner_id=owner_id, name=name, address=address, location=point)
    db.session.add(shop)
    db.session.commit()

    return jsonify({"ok": True, "shop_id": shop.id}), 201
