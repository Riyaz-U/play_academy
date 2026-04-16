import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String name;
  final String location;
  final String city;
  final String organizationId;
  final DateTime createdAt;

  const BranchModel({
    required this.id,
    required this.name,
    required this.location,
    required this.city,
    required this.organizationId,
    required this.createdAt,
  });

  factory BranchModel.fromMap(Map<String, dynamic> map, String id) {
    return BranchModel(
      id: id,
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      city: map['city'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'city': city,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
