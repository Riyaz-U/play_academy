import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class AttendanceModel {
  final String id; // Format: {sessionId}_{playerId}
  final String sessionId;
  final String playerId;
  final String playerName;
  final String status; // 'present' | 'absent' | 'late'
  final int? rating; // 1–5, given by coach after session
  final String? ratingNote;
  final String markedBy; // coach uid
  final String markedByName;
  final DateTime markedAt;
  final String organizationId;
  final String branchId;

  const AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.playerName,
    required this.status,
    this.rating,
    this.ratingNote,
    required this.markedBy,
    required this.markedByName,
    required this.markedAt,
    required this.organizationId,
    required this.branchId,
  });

  bool get isPresent => status == AppConstants.attendancePresent;
  bool get isAbsent => status == AppConstants.attendanceAbsent;
  bool get isLate => status == AppConstants.attendanceLate;
  bool get attended => isPresent || isLate;

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      sessionId: map['sessionId'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      status: map['status'] as String? ?? AppConstants.attendanceAbsent,
      rating: (map['rating'] as num?)?.toInt(),
      ratingNote: map['ratingNote'] as String?,
      markedBy: map['markedBy'] as String? ?? '',
      markedByName: map['markedByName'] as String? ?? '',
      markedAt: map['markedAt'] != null
          ? (map['markedAt'] as Timestamp).toDate()
          : DateTime.now(),
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'playerId': playerId,
      'playerName': playerName,
      'status': status,
      if (rating != null) 'rating': rating,
      if (ratingNote != null) 'ratingNote': ratingNote,
      'markedBy': markedBy,
      'markedByName': markedByName,
      'markedAt': Timestamp.fromDate(markedAt),
      'organizationId': organizationId,
      'branchId': branchId,
    };
  }
}
