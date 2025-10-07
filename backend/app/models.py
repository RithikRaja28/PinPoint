from datetime import datetime
from geoalchemy2 import Geography
from .db import db

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    phone = db.Column(db.String(30), unique=True, nullable=True)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(30), default='customer')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    shops = db.relationship('Shop', backref='owner', lazy=True)

class Shop(db.Model):
    __tablename__ = 'shops'
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(150), nullable=False)
    address = db.Column(db.Text)
    location = db.Column(Geography(geometry_type='POINT', srid=4326), nullable=True)
    registered_shop_id = db.Column(db.String(100), nullable=True)
    gps_verified = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
class Campaign(db.Model):
    __tablename__ = 'campaigns'
    id = db.Column(db.Integer, primary_key=True)
    shop_id = db.Column(db.Integer, db.ForeignKey('shops.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    meta_data = db.Column(db.JSON, default={})  
    start_at = db.Column(db.DateTime)
    end_at = db.Column(db.DateTime)
    active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    shop = db.relationship('Shop', backref='campaigns')
