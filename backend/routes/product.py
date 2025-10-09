import os
import time
from flask import Blueprint, request, jsonify, current_app
from database import db
from models.product_model import ProductModel
from sqlalchemy import or_

product_bp = Blueprint("product", __name__)

def _save_upload(file_obj, prefix="product"):
    """Save uploaded FileStorage to UPLOAD_FOLDER and return URL path (/uploads/...)."""
    if not file_obj:
        return None
    try:
        filename = f"{prefix}_{int(time.time())}_{file_obj.filename}"
        upload_folder = current_app.config.get("UPLOAD_FOLDER") or os.path.join(os.getcwd(), "uploads")
        os.makedirs(upload_folder, exist_ok=True)
        save_path = os.path.join(upload_folder, filename)
        file_obj.save(save_path)
        # return relative URL path for your uploads route
        return f"/uploads/{filename}"
    except Exception as e:
        current_app.logger.exception("Failed to save upload: %s", e)
        return None

# Create
@product_bp.route("/", methods=["POST"])
def create_product():
    try:
        # accept multipart/form-data (image + fields) or JSON
        if request.content_type and request.content_type.startswith("application/json"):
            payload = request.get_json(silent=True) or {}
        else:
            payload = request.form.to_dict() or {}

        # require owner_uid and name and price
        owner_uid = payload.get("owner_uid") or request.headers.get("X-Owner-Uid")
        name = payload.get("name")
        price = payload.get("price")

        if not owner_uid:
            return jsonify({"error": "owner_uid is required"}), 400
        if not name:
            return jsonify({"error": "product name is required"}), 400
        try:
            price_f = float(price) if price is not None else 0.0
        except Exception:
            return jsonify({"error": "price must be a number"}), 400

        image_url = None
        if "image" in request.files:
            image_file = request.files.get("image")
            saved = _save_upload(image_file, prefix="product")
            if saved:
                image_url = saved

        # fallback url field
        if not image_url and payload.get("image_url"):
            image_url = payload.get("image_url")

        p = ProductModel(
            owner_uid=owner_uid,
            name=name,
            description=payload.get("description"),
            price=price_f,
            image_url=image_url
        )
        db.session.add(p)
        db.session.commit()
        return jsonify({"message": "Product created", "product": p.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        current_app.logger.exception("Failed to create product: %s", e)
        return jsonify({"error": str(e)}), 500

# Read list for owner (paginated)
@product_bp.route("/", methods=["GET"])
def list_products():
    try:
        owner_uid = request.args.get("owner_uid") or request.headers.get("X-Owner-Uid")
        q = request.args.get("q", type=str)
        limit = int(request.args.get("limit", 50))
        offset = int(request.args.get("offset", 0))

        if not owner_uid:
            return jsonify({"error": "owner_uid required to list products"}), 400

        query = ProductModel.query.filter_by(owner_uid=owner_uid)
        if q:
            like = f"%{q}%"
            query = query.filter(or_(ProductModel.name.ilike(like), ProductModel.description.ilike(like)))
        total = query.count()
        items = query.order_by(ProductModel.created_at.desc()).offset(offset).limit(limit).all()

        return jsonify({
            "count": total,
            "products": [p.to_dict() for p in items]
        }), 200
    except Exception as e:
        current_app.logger.exception("List products error: %s", e)
        return jsonify({"error": str(e)}), 500

# Read single product
@product_bp.route("/<int:product_id>", methods=["GET"])
def get_product(product_id):
    p = ProductModel.query.get_or_404(product_id)
    return jsonify({"product": p.to_dict()}), 200

# Update (owner only)
@product_bp.route("/<int:product_id>", methods=["PUT", "PATCH"])
def update_product(product_id):
    try:
        p = ProductModel.query.get_or_404(product_id)
        # owner_uid enforcement: require owner_uid in payload or header and match
        if request.content_type and request.content_type.startswith("application/json"):
            payload = request.get_json(silent=True) or {}
        else:
            payload = request.form.to_dict() or {}

        caller_owner = payload.get("owner_uid") or request.headers.get("X-Owner-Uid")
        if caller_owner and caller_owner != p.owner_uid:
            return jsonify({"error": "not allowed"}), 403

        # apply updates
        if "name" in payload and payload.get("name"):
            p.name = payload.get("name")
        if "description" in payload:
            p.description = payload.get("description")
        if "price" in payload and payload.get("price") != "":
            try:
                p.price = float(payload.get("price"))
            except Exception:
                return jsonify({"error": "price must be numeric"}), 400

        # handle image upload
        if "image" in request.files:
            image_file = request.files.get("image")
            saved = _save_upload(image_file, prefix="product")
            if saved:
                p.image_url = saved

        db.session.commit()
        return jsonify({"message": "Product updated", "product": p.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        current_app.logger.exception("Update product error: %s", e)
        return jsonify({"error": str(e)}), 500

# Delete (owner only)
@product_bp.route("/<int:product_id>", methods=["DELETE"])
def delete_product(product_id):
    try:
        p = ProductModel.query.get_or_404(product_id)
        caller_owner = request.args.get("owner_uid") or request.headers.get("X-Owner-Uid")
        if caller_owner and caller_owner != p.owner_uid:
            return jsonify({"error": "not allowed"}), 403

        db.session.delete(p)
        db.session.commit()
        return jsonify({"message": "Product deleted"}), 200
    except Exception as e:
        db.session.rollback()
        current_app.logger.exception("Delete product error: %s", e)
        return jsonify({"error": str(e)}), 500
