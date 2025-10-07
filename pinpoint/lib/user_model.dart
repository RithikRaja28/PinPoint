import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { normal, business }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserType userType;
  final String? shopName;
  final String? shopContact;
  final double? shopLat;
  final double? shopLng;
  final Timestamp? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.shopName,
    this.shopContact,
    this.shopLat,
    this.shopLng,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] == 'business'
          ? UserType.business
          : UserType.normal,
      shopName: map['shopName'],
      shopContact: map['shopContact'],
      shopLat: map['shopLocation']?['lat']?.toDouble(),
      shopLng: map['shopLocation']?['lng']?.toDouble(),
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType == UserType.business ? 'business' : 'normal',
      if (userType == UserType.business) ...{
        'shopName': shopName,
        'shopContact': shopContact,
        'shopLocation': {'lat': shopLat ?? 20.5937, 'lng': shopLng ?? 78.9629},
      },
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
