import 'package:cloud_firestore/cloud_firestore.dart';

class DrillModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String sport;
  final String? teamId;
  final String? videoUrl;
  final String organizationId;
  final String branchId;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  const DrillModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.sport,
    this.teamId,
    this.videoUrl,
    required this.organizationId,
    required this.branchId,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  factory DrillModel.fromMap(Map<String, dynamic> map, String id) {
    return DrillModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? DrillCategory.technical,
      sport: map['sport'] as String? ?? '',
      teamId: map['teamId'] as String?,
      videoUrl: map['videoUrl'] as String?,
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'sport': sport,
        if (teamId != null) 'teamId': teamId,
        if (videoUrl != null && videoUrl!.isNotEmpty) 'videoUrl': videoUrl,
        'organizationId': organizationId,
        'branchId': branchId,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class DrillCategory {
  static const String technical = 'technical';
  static const String tactical = 'tactical';
  static const String physical = 'physical';
  static const String mental = 'mental';

  static const List<String> all = [technical, tactical, physical, mental];

  static String label(String category) {
    switch (category) {
      case technical:
        return 'Technical';
      case tactical:
        return 'Tactical';
      case physical:
        return 'Physical';
      case mental:
        return 'Mental';
      default:
        return category;
    }
  }
}
