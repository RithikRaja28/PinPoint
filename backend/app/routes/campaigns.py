# from flask import Blueprint, request, jsonify
# from flask_jwt_extended import jwt_required, get_jwt_identity
# from ..db import db
# from ..models import Campaign, Shop

# campaigns_bp = Blueprint('campaigns', __name__)

# @campaigns_bp.route('/create', methods=['POST'])
# @jwt_required()
# def create_campaign():
#     user_id = get_jwt_identity()
#     data = request.json or {}
#     shop_id = data.get('shop_id')
#     title = data.get('title')

#     shop = Shop.query.get(shop_id)
#     if not shop or shop.owner_id != user_id:
#         return jsonify({'error': 'invalid shop or permission denied'}), 403

#     campaign = Campaign(
#         shop_id=shop_id,
#         title=title,
#         description=data.get('description'),
#         meta_data=data.get('metadata') or {}

#     )
#     db.session.add(campaign)
#     db.session.commit()

#     return jsonify({'campaign_id': campaign.id, 'title': campaign.title})

# @campaigns_bp.route('/list/<int:shop_id>', methods=['GET'])
# def list_campaigns(shop_id):
#     campaigns = Campaign.query.filter_by(shop_id=shop_id).order_by(Campaign.created_at.desc()).all()
#     out = []
#     for c in campaigns:
#         out.append({
#             'id': c.id,
#             'title': c.title,
#             'active': c.active,
#             'start_at': c.start_at,
#             'end_at': c.end_at
#         })
#     return jsonify({'campaigns': out})
