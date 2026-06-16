import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class SessionModel {
  final String id;
  final String title;
  final String type;
  final DateTime dateTime;
  final String location;
  final String notes;
  final String? sport;
  final String? category;
  final String? teamId;
  final String organizationId;
  final String branchId;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool isCompleted;
  final String? highlights;

  const SessionModel({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.location,
    required this.notes,
    this.sport,
    this.category,
    this.teamId,
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
  bool get isTeamSession => teamId != null;

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
      sport: map['sport'] as String?,
      category: map['category'] as String?,
      teamId: map['teamId'] as String?,
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
      if (sport != null) 'sport': sport,
      if (category != null) 'category': category,
      if (teamId != null) 'teamId': teamId,
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
