from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from geoalchemy2.shape import from_shape
from shapely.geometry import Point
from ..db import db
from ..models import Shop
from sqlalchemy import text

shops_bp = Blueprint('shops', __name__)

@shops_bp.route('/create', methods=['POST'])
@jwt_required()
def create_shop():
    user_id = get_jwt_identity()
    data = request.json or {}
    name = data.get('name')
    address = data.get('address')
    lat = data.get('latitude')
    lon = data.get('longitude')

    if not name or lat is None or lon is None:
        return jsonify({'error': 'name, latitude, longitude required'}), 400

    point = from_shape(Point(float(lon), float(lat)), srid=4326)
    shop = Shop(owner_id=user_id, name=name, address=address, location=point)

    db.session.add(shop)
    db.session.commit()

    return jsonify({'shop_id': shop.id, 'name': shop.name})


@shops_bp.route('/', methods=['GET'])
def helperrr():
    return "working"

@shops_bp.route('/nearby', methods=['GET'])
def nearby_shops():
    lat = request.args.get('lat', type=float)
    lon = request.args.get('lon', type=float)
    radius = request.args.get('radius', type=float, default=1000.0)

    if lat is None or lon is None:
        return jsonify({'error': 'lat and lon required as query params'}), 400

    sql = text(
        "SELECT id, name, address, ST_AsText(location) AS location_wkt, "
        "ST_Distance(location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) as distance_m "
        "FROM shops "
        "WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, :radius) "
        "ORDER BY distance_m ASC LIMIT 100"
    )
    rows = db.session.execute(sql, {'lon': lon, 'lat': lat, 'radius': radius}).fetchall()
    result = []
    for r in rows:
        result.append({
            'id': r.id,
            'name': r.name,
            'address': r.address,
            'location_wkt': r.location_wkt,
            'distance_m': float(r.distance_m)
        })
    return jsonify({'nearby': result})