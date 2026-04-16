import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class SessionModel {
  final String id;
  final String title;
  final String type; // 'training' | 'match'
  final DateTime dateTime;
  final String location;
  final String notes;
  final String? category; // null = all categories, or specific age group
  final String organizationId;
  final String branchId;
  final String createdBy; // coach uid
  final String createdByName; // coach name for display
  final DateTime createdAt;
  final bool isCompleted;
  final String? highlights; // text or video URL added after completion

  const SessionModel({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.location,
    required this.notes,
    this.category,
    required this.organizationId,
    required this.branchId,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.isCompleted,
    this.highlights,
  });

  bool get isTraining => type == AppConstants.sessionTypeTraining;
  bool get isMatch => type == AppConstants.sessionTypeMatch;
  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: id,
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? AppConstants.sessionTypeTraining,
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      category: map['category'] as String?,
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      highlights: map['highlights'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'notes': notes,
      if (category != null) 'category': category,
      'organizationId': organizationId,
      'branchId': branchId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isCompleted': isCompleted,
      if (highlights != null) 'highlights': highlights,
    };
  }
}
