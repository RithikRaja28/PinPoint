from database import db

class CampaignModel(db.Model):
    __tablename__ = 'campaigns'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    offer = db.Column(db.Text, nullable=False)
    radius_km = db.Column(db.Float, nullable=False)
    start = db.Column(db.DateTime, nullable=False)
    end = db.Column(db.DateTime, nullable=False)
    poster_path = db.Column(db.String(200), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'offer': self.offer,
            'radius_km': self.radius_km,
            'start': self.start.isoformat(),
            'end': self.end.isoformat(),
            'poster_path': self.poster_path
        }
