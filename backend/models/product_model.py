from datetime import datetime
from database import db

class ProductModel(db.Model):
    __tablename__ = "products"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    owner_uid = db.Column(db.String(128), index=True, nullable=False)  # link to shops.owner_uid / firebase uid
    name = db.Column(db.String(200), nullable=False, index=True)
    description = db.Column(db.Text, nullable=True)
    price = db.Column(db.Numeric(10,2), nullable=False, default=0.00)
    image_url = db.Column(db.String(1024), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "owner_uid": self.owner_uid,
            "name": self.name,
            "description": self.description,
            "price": float(self.price) if self.price is not None else 0.0,
            "image_url": self.image_url,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
