from datetime import datetime
from app.db import db
from geoalchemy2 import Geography

class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    email = db.Column(db.String(120))
    role = db.Column(db.String(30), default="customer")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Shop(db.Model):
    __tablename__ = "shops"
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    name = db.Column(db.String(120), nullable=False)
    address = db.Column(db.Text)
    # PostGIS POINT: use Geography to store lat/lon (SRID 4326)
    location = db.Column(Geography(geometry_type='POINT', srid=4326))
    registered_shop_id = db.Column(db.String(80))
    gps_verified = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
