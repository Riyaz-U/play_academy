import 'package:cloud_firestore/cloud_firestore.dart';

class BatchModel {
  final String id;
  final String name;
  final String sport;
  final String category;
  final String branchId;
  final String organizationId;
  final String createdBy;
  final DateTime createdAt;

  const BatchModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.category,
    required this.branchId,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
  });

  factory BatchModel.fromMap(Map<String, dynamic> map, String id) {
    return BatchModel(
      id: id,
      name: map['name'] as String? ?? '',
      sport: map['sport'] as String? ?? '',
      category: map['category'] as String? ?? '',
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
        'category': category,
        'branchId': branchId,
        'organizationId': organizationId,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
