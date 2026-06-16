import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String sport;
  final String branchId;
  final String organizationId;
  final String createdBy;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.branchId,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamModel(
      id: id,
      name: map['name'] as String? ?? '',
      sport: map['sport'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sport': sport,
        'branchId': branchId,
        'organizationId': organizationId,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
