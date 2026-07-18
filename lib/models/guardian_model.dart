import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String organizationId;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  const GuardianModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  factory GuardianModel.fromMap(Map<String, dynamic> map, String uid) {
    return GuardianModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'organizationId': organizationId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
