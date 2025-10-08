from datetime import datetime
from database import db

class ShopModel(db.Model):
    __tablename__ = "shops"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    owner_uid = db.Column(db.String(128), index=True, nullable=True)
    name = db.Column(db.String(180), nullable=False, index=True)
    category = db.Column(db.String(80), nullable=True)
    description = db.Column(db.Text, nullable=True)

    address_line = db.Column(db.String(300), nullable=True)
    city = db.Column(db.String(120), nullable=True)

    lat = db.Column(db.Numeric(9,6), nullable=True, index=True)
    lon = db.Column(db.Numeric(9,6), nullable=True, index=True)

    registration_no = db.Column(db.String(80), nullable=True)
    contact_number = db.Column(db.String(32), nullable=True)

    avg_spend = db.Column(db.Numeric(10,2), nullable=True)
    has_offer = db.Column(db.Boolean, default=False)

    image_url = db.Column(db.String(1024), nullable=True)
    logo_url = db.Column(db.String(1024), nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "owner_uid": self.owner_uid,
            "name": self.name,
            "category": self.category,
            "description": self.description,
            "address_line": self.address_line,
            "city": self.city,
            "lat": float(self.lat) if self.lat else None,
            "lon": float(self.lon) if self.lon else None,
            "registration_no": self.registration_no,
            "contact_number": self.contact_number,
            "avg_spend": float(self.avg_spend) if self.avg_spend else None,
            "has_offer": self.has_offer,
            "image_url": self.image_url,
            "logo_url": self.logo_url,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
