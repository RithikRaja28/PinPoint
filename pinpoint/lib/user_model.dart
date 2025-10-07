import 'package:cloud_firestore/cloud_firestore.dart';

// Defines the two types of users the application supports
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
  final String? address;
  final String? description;
  final String? city;
  final String? district;

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
    this.address,
    this.description,
    this.city,
    this.district,
  });

  /// Creates a UserModel instance from a Firestore map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Guest User',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] == 'business'
          ? UserType.business
          : UserType.normal,
      shopName: map['shopName'],
      shopContact: map['shopContact'],
      // Safely access nested shop location data
      shopLat: map['shopLocation']?['lat']?.toDouble(),
      shopLng: map['shopLocation']?['lng']?.toDouble(),
      createdAt: map['createdAt'],
      address: map['address'],
      description: map['description'],
      city: map['city'],
      district: map['district'],
    );
  }

  /// Converts the UserModel instance to a map suitable for Firestore.
  /// Note: The 'createdAt' field uses FieldValue.serverTimestamp() if null,
  /// which is ideal for creating a new document but should be handled
  /// externally for updates.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType == UserType.business ? 'business' : 'normal',
      // Include common optional fields
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'address': address,
      'description': description,
      'city': city,
      'district': district,
    };

    // Include business-specific fields only if the user is a business
    if (userType == UserType.business) {
      data.addAll({
        'shopName': shopName,
        'shopContact': shopContact,
        // Using default coordinates if location is missing for a business account
        'shopLocation': {'lat': shopLat ?? 20.5937, 'lng': shopLng ?? 78.9629},
      });
    }
    return data;
  }

  /// Creates a copy of the model with optional updated values.
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserType? userType,
    String? shopName,
    String? shopContact,
    double? shopLat,
    double? shopLng,
    Timestamp? createdAt,
    String? address,
    String? description,
    String? city,
    String? district,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      shopName: shopName ?? this.shopName,
      shopContact: shopContact ?? this.shopContact,
      shopLat: shopLat ?? this.shopLat,
      shopLng: shopLng ?? this.shopLng,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      description: description ?? this.description,
      city: city ?? this.city,
      district: district ?? this.district,
    );
  }
}
