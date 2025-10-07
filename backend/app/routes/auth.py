from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token
from ..db import db
from ..models import User

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json or {}
    username = data.get('username')
    password = data.get('password')
    phone = data.get('phone')

    if not username or not password:
        return jsonify({'error': 'username and password required'}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'username exists'}), 400

    user = User(username=username, phone=phone, password_hash=generate_password_hash(password))
    db.session.add(user)
    db.session.commit()

    token = create_access_token(identity=user.id)
    return jsonify({'access_token': token, 'user_id': user.id})

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json or {}
    username = data.get('username')
    password = data.get('password')

    user = User.query.filter_by(username=username).first()
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({'error': 'invalid credentials'}), 401

    token = create_access_token(identity=user.id)
    return jsonify({'access_token': token, 'user_id': user.id})