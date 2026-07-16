import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerHealth {
  final String? height;
  final String? weight;
  final String? bloodGroup;
  final String? allergies;
  final String? medications;

  const PlayerHealth({
    this.height,
    this.weight,
    this.bloodGroup,
    this.allergies,
    this.medications,
  });

  factory PlayerHealth.fromMap(Map<String, dynamic> map) {
    return PlayerHealth(
      height: map['height'] as String?,
      weight: map['weight'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      allergies: map['allergies'] as String?,
      medications: map['medications'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (allergies != null) 'allergies': allergies,
        if (medications != null) 'medications': medications,
      };

  bool get isEmpty =>
      height == null &&
      weight == null &&
      bloodGroup == null &&
      allergies == null &&
      medications == null;
}

class PlayerModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String phone;
  final String organizationId;
  final String branchId;
  final String createdBy;
  final DateTime createdAt;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final PlayerHealth health;
  final String? bio;
  final bool isActive;
  final String? guardianUid;

  const PlayerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.phone,
    required this.organizationId,
    required this.branchId,
    required this.createdBy,
    required this.createdAt,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.health = const PlayerHealth(),
    this.bio,
    this.isActive = true,
    this.guardianUid,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map, String uid) {
    return PlayerModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      phone: map['phone'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      parentName: map['parentName'] as String?,
      parentPhone: map['parentPhone'] as String?,
      parentEmail: map['parentEmail'] as String?,
      health: map['health'] != null
          ? PlayerHealth.fromMap(map['health'] as Map<String, dynamic>)
          : const PlayerHealth(),
      bio: map['bio'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      guardianUid: map['guardianUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'phone': phone,
      'organizationId': organizationId,
      'branchId': branchId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (parentName != null && parentName!.isNotEmpty) 'parentName': parentName,
      if (parentPhone != null && parentPhone!.isNotEmpty) 'parentPhone': parentPhone,
      if (parentEmail != null && parentEmail!.isNotEmpty) 'parentEmail': parentEmail,
      if (!health.isEmpty) 'health': health.toMap(),
      if (bio != null && bio!.isNotEmpty) 'bio': bio,
      'isActive': isActive,
      if (guardianUid != null && guardianUid!.isNotEmpty) 'guardianUid': guardianUid,
    };
  }
}
