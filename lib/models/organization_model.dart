import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String adminName;
  final String email;
  final String phone;
  final String? city;
  final DateTime createdAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.adminName,
    required this.email,
    required this.phone,
    this.city,
    required this.createdAt,
  });

  factory OrganizationModel.fromMap(Map<String, dynamic> map, String id) {
    return OrganizationModel(
      id: id,
      name: map['name'] as String? ?? '',
      adminName: map['adminName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminName': adminName,
      'email': email,
      'phone': phone,
      if (city != null) 'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
