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
  final List<String> batchIds;
  final List<String> playerIds;
  final String organizationId;
  final String branchId;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final int durationMinutes;
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
    this.batchIds = const [],
    this.playerIds = const [],
    required this.organizationId,
    required this.branchId,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.durationMinutes = 90,
    required this.isCompleted,
    this.highlights,
  });

  DateTime get endTime =>
      dateTime.add(Duration(minutes: durationMinutes));

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
      sport: map['sport'] as String?,
      category: map['category'] as String?,
      batchIds: (map['batchIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      playerIds: (map['playerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      durationMinutes: map['durationMinutes'] as int? ?? 90,
      isCompleted: map['isCompleted'] as bool? ?? false,
      highlights: map['highlights'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'location': location,
      'notes': notes,
      if (sport != null) 'sport': sport,
      if (category != null) 'category': category,
      'batchIds': batchIds,
      'playerIds': playerIds,
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
