from datetime import datetime
from database import db

class DeviceModel(db.Model):
    __tablename__ = "devices"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    uid = db.Column(db.String(128), unique=True, index=True, nullable=False)
    phone_number = db.Column(db.String(32), nullable=True)

    latitude = db.Column(db.Numeric(9,6), nullable=True, index=True)
    longitude = db.Column(db.Numeric(9,6), nullable=True, index=True)

    c_status = db.Column(
        db.Enum("CONNECTED_DATA", "CONNECTED_SMS", "NOT_CONNECTED", name="connection_status_enum"),
        nullable=False,
        default="NOT_CONNECTED"
    )

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "uid": self.uid,
            "phone_number": self.phone_number,
            "latitude": float(self.latitude) if self.latitude else None,
            "longitude": float(self.longitude) if self.longitude else None,
            "c_status": self.c_status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
