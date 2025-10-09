from flask import Blueprint, request, jsonify, current_app
from database import db
from models.device_model import DeviceModel  # make sure you save the earlier model as device_model.py
from datetime import datetime
from sqlalchemy.exc import SQLAlchemyError

device_bp = Blueprint("device", __name__)

@device_bp.route("/", methods=["POST"])
def create_device():
    """
    Create a new device entry.
    Expected JSON body:
    {
        "uid": "string (required)",
        "phone_number": "string",
        "latitude": 12.345678,
        "longitude": 98.765432,
        "c_status": "CONNECTED_DATA" | "CONNECTED_SMS" | "NOT_CONNECTED"
    }
    """
    try:
        data = request.get_json(silent=True) or {}

        uid = data.get("uid")
        if not uid:
            return jsonify({"error": "Device UID is required"}), 400

        c_status = data.get("c_status", "NOT_CONNECTED")
        if c_status not in ["CONNECTED_DATA", "CONNECTED_SMS", "NOT_CONNECTED"]:
            return jsonify({"error": "Invalid c_status value"}), 400

        device = DeviceModel(
            uid=uid,
            phone_number=data.get("phone_number"),
            latitude=float(data.get("latitude")) if data.get("latitude") else None,
            longitude=float(data.get("longitude")) if data.get("longitude") else None,
            c_status=c_status
        )

        db.session.add(device)
        db.session.commit()

        return jsonify({"message": "Device created", "device": device.to_dict()}), 201

    except SQLAlchemyError as e:
        db.session.rollback()
        current_app.logger.exception("Database error while creating device: %s", e)
        return jsonify({"error": "Database error"}), 500
    except Exception as e:
        db.session.rollback()
        current_app.logger.exception("Failed to create device: %s", e)
        return jsonify({"error": str(e)}), 500


@device_bp.route("/<string:uid>", methods=["GET"])
def get_device(uid):
    """Fetch a single device by its UID."""
    device = DeviceModel.query.filter_by(uid=uid).first()
    if not device:
        return jsonify({"error": "Device not found"}), 404
    return jsonify(device.to_dict()), 200


@device_bp.route("/all", methods=["GET"])
def get_all_devices():
    """List all devices."""
    devices = DeviceModel.query.order_by(DeviceModel.created_at.desc()).all()
    return jsonify({"count": len(devices), "devices": [d.to_dict() for d in devices]}), 200


@device_bp.route("/test", methods=["GET"])
def test_device():
    """Simple health check route."""
    return "Device endpoint is working!", 200
