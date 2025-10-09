from flask import Blueprint, request, jsonify, current_app
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

@shop_bp.route("/active_campaigns_nearby", methods=["GET"])
def active_campaigns_nearby():
    """
    Query params:
      lat (required), lon (required),
      radius_m (optional, default 10000),  -- maximum 10km by default
      limit (optional, default 50)

    Returns a list of active campaigns joined with shop details ordered by nearest first.
    Each item contains both campaign and shop fields so frontend can render offers.
    """
    # parse lat/lon
    try:
        lat = float(request.args.get("lat", None))
        lon = float(request.args.get("lon", None))
    except Exception:
        return jsonify({"error": "lat and lon query parameters required and must be numeric"}), 400

    # radius (meters) default 10km
    try:
        radius_m = float(request.args.get("radius", 10000))
    except Exception:
        radius_m = 10000.0

    # cap to 10km for safety (remove if you want)
    if radius_m > 10000:
        radius_m = 10000.0

    try:
        limit = int(request.args.get("limit", 50))
    except Exception:
        limit = 50

    # PostGIS query: join shops -> campaigns where campaign active
    postgis_sql = """
    SELECT
      s.id        AS shop_id,
      s.owner_uid AS shop_owner_uid,
      s.name      AS shop_name,
      s.category  AS shop_category,
      s.description AS shop_description,
      s.address_line,
      s.city,
      s.lat,
      s.lon,
      s.avg_spend,
      s.image_url,
      c.id        AS campaign_id,
      c.owner_uid AS campaign_owner_uid,
      c.title     AS campaign_title,
      c.offer     AS campaign_offer,
      c.poster_path,
      c.radius_km,
      c.start     AS campaign_start,
      c.end       AS campaign_end,
      -- compute distance in meters using geography
      ST_Distance(
        ST_SetSRID(ST_MakePoint(COALESCE(s.lon,0), COALESCE(s.lat,0)), 4326)::geography,
        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
      ) AS distance_m
    FROM shops s
    JOIN campaigns c
      ON c.owner_uid IS NOT NULL
      AND c.owner_uid = s.owner_uid
    WHERE s.lat IS NOT NULL AND s.lon IS NOT NULL
      AND c.start <= now() AT TIME ZONE 'utc'
      AND c.end >= now() AT TIME ZONE 'utc'
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
        # PostGIS missing or syntax error -> fallback to Haversine raw SQL
        current_app.logger.warning("PostGIS query failed, falling back to Haversine: %s", pe)

        # Haversine (meters) — earth radius 6371000
        haversine_sql = """
        SELECT
          s.id        AS shop_id,
          s.owner_uid AS shop_owner_uid,
          s.name      AS shop_name,
          s.category  AS shop_category,
          s.description AS shop_description,
          s.address_line,
          s.city,
          s.lat,
          s.lon,
          s.avg_spend,
          s.image_url,
          c.id        AS campaign_id,
          c.owner_uid AS campaign_owner_uid,
          c.title     AS campaign_title,
          c.offer     AS campaign_offer,
          c.poster_path,
          c.radius_km,
          c.start     AS campaign_start,
          c.end       AS campaign_end,
          (6371000 * 2 * asin(sqrt(
            power(sin(radians((COALESCE(s.lat,0) - :lat)/2)),2) +
            cos(radians(:lat)) * cos(radians(COALESCE(s.lat,0))) *
            power(sin(radians((COALESCE(s.lon,0) - :lon)/2)),2)
          ))) AS distance_m
        FROM shops s
        JOIN campaigns c
          ON c.owner_uid IS NOT NULL
          AND c.owner_uid = s.owner_uid
        WHERE s.lat IS NOT NULL AND s.lon IS NOT NULL
          AND c.start <= now() AT TIME ZONE 'utc'
          AND c.end >= now() AT TIME ZONE 'utc'
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
        current_app.logger.exception("Error running active campaigns nearby query: %s", e)
        return jsonify({"error": "Internal server error"}), 500

    # Build response
    results = []
    for r in rows:
        # Access by column names
        shop_id = getattr(r, "shop_id", None)
        shop_name = getattr(r, "shop_name", None)
        shop_category = getattr(r, "shop_category", None)
        shop_description = getattr(r, "shop_description", None) or ""
        shop_lat = getattr(r, "lat", None)
        shop_lon = getattr(r, "lon", None)
        avg_spend = getattr(r, "avg_spend", None)
        image_url = getattr(r, "image_url", None)

        campaign_id = getattr(r, "campaign_id", None)
        campaign_title = getattr(r, "campaign_title", None)
        campaign_offer = getattr(r, "campaign_offer", None)
        poster_path = getattr(r, "poster_path", None)
        campaign_start = getattr(r, "campaign_start", None)
        campaign_end = getattr(r, "campaign_end", None)

        distance_m = getattr(r, "distance_m", None)
        try:
            distance_m_f = float(distance_m) if distance_m is not None else None
        except Exception:
            distance_m_f = None

        try:
            avg_spend_f = float(avg_spend) if avg_spend is not None else None
        except Exception:
            avg_spend_f = None

        # optional randomized rating for frontend
        rating = round(random.uniform(3.5, 5.0), 1)

        results.append({
            "shop": {
                "id": shop_id,
                "owner_uid": getattr(r, "shop_owner_uid", None),
                "name": shop_name,
                "category": shop_category,
                "description": shop_description,
                "address_line": getattr(r, "address_line", None),
                "city": getattr(r, "city", None),
                "lat": float(shop_lat) if shop_lat is not None else None,
                "lon": float(shop_lon) if shop_lon is not None else None,
                "avgSpend": avg_spend_f,
                "imageUrl": image_url,
                "rating": rating,
            },
            "campaign": {
                "id": campaign_id,
                "owner_uid": getattr(r, "campaign_owner_uid", None),
                "title": campaign_title,
                "offer": campaign_offer,
                "poster_path": poster_path,
                "start": campaign_start.isoformat() if campaign_start else None,
                "end": campaign_end.isoformat() if campaign_end else None,
                "radius_km": getattr(r, "radius_km", None),
            },
            "distanceMeters": distance_m_f,
        })

    return jsonify({"count": len(results), "items": results}), 200