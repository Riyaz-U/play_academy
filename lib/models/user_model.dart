import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String organizationId;
  final String? branchId; // null for org_admin
  final String? fcmToken;
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.organizationId,
    this.branchId,
    this.fcmToken,
    required this.createdAt,
    this.isActive = true,
  });

  bool get isOrgAdmin => role == AppConstants.roleOrgAdmin;
  bool get isCoach => role == AppConstants.roleCoach;
  bool get isPlayer => role == AppConstants.rolePlayer;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? AppConstants.rolePlayer,
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String?,
      fcmToken: map['fcmToken'] as String?,
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
      'role': role,
      'organizationId': organizationId,
      if (branchId != null) 'branchId': branchId,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  UserModel copyWith({String? name, String? fcmToken, String? branchId, bool? isActive}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      organizationId: organizationId,
      branchId: branchId ?? this.branchId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
