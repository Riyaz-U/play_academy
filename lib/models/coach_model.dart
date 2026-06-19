import 'package:cloud_firestore/cloud_firestore.dart';

class CoachModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String organizationId;
  final String branchId;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  const CoachModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.organizationId,
    required this.branchId,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  factory CoachModel.fromMap(Map<String, dynamic> map, String uid) {
    return CoachModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
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
      'branchId': branchId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
