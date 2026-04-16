import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String position;
  final int jerseyNumber;
  final String phone;
  final String category; // U13, U15, U17, U18, U19, U21, Senior
  final String organizationId;
  final String branchId;
  final String createdBy;
  final DateTime createdAt;

  const PlayerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.position,
    required this.jerseyNumber,
    required this.phone,
    required this.category,
    required this.organizationId,
    required this.branchId,
    required this.createdBy,
    required this.createdAt,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map, String uid) {
    return PlayerModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      position: map['position'] as String? ?? 'Forward',
      jerseyNumber: (map['jerseyNumber'] as num?)?.toInt() ?? 0,
      phone: map['phone'] as String? ?? '',
      category: map['category'] as String? ?? 'Senior',
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'position': position,
      'jerseyNumber': jerseyNumber,
      'phone': phone,
      'category': category,
      'organizationId': organizationId,
      'branchId': branchId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
