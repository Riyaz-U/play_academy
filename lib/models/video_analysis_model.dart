import 'package:cloud_firestore/cloud_firestore.dart';

class VideoAnnotation {
  final String id;
  final String videoId;
  final double timestamp; // seconds into the video
  final String note;
  final String type; // tactical / technical / feedback
  final String? playerId;
  final String? playerName;
  final String authorUid;
  final String authorName;
  final DateTime createdAt;

  const VideoAnnotation({
    required this.id,
    required this.videoId,
    required this.timestamp,
    required this.note,
    required this.type,
    this.playerId,
    this.playerName,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
  });

  factory VideoAnnotation.fromMap(Map<String, dynamic> map, String id) {
    return VideoAnnotation(
      id: id,
      videoId: map['videoId'] as String? ?? '',
      timestamp: (map['timestamp'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String? ?? '',
      type: map['type'] as String? ?? AnnotationType.feedback,
      playerId: map['playerId'] as String?,
      playerName: map['playerName'] as String?,
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'videoId': videoId,
        'timestamp': timestamp,
        'note': note,
        'type': type,
        if (playerId != null) 'playerId': playerId,
        if (playerName != null) 'playerName': playerName,
        'authorUid': authorUid,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Format timestamp as mm:ss
  String get timestampLabel {
    final mins = (timestamp ~/ 60).toString().padLeft(2, '0');
    final secs = (timestamp % 60).toInt().toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class AnnotationType {
  static const String tactical = 'tactical';
  static const String technical = 'technical';
  static const String feedback = 'feedback';

  static const List<String> all = [tactical, technical, feedback];

  static String label(String type) {
    switch (type) {
      case tactical:
        return 'Tactical';
      case technical:
        return 'Technical';
      case feedback:
        return 'Feedback';
      default:
        return type;
    }
  }
}

class VideoAnalysisModel {
  final String id;
  final String title;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? category; // match / training session title
  final String uploadedBy;
  final String uploadedByName;
  final String organizationId;
  final String branchId;
  final DateTime createdAt;

  const VideoAnalysisModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.thumbnailUrl,
    this.category,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.organizationId,
    required this.branchId,
    required this.createdAt,
  });

  factory VideoAnalysisModel.fromMap(Map<String, dynamic> map, String id) {
    return VideoAnalysisModel(
      id: id,
      title: map['title'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String?,
      category: map['category'] as String?,
      uploadedBy: map['uploadedBy'] as String? ?? '',
      uploadedByName: map['uploadedByName'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'videoUrl': videoUrl,
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
          'thumbnailUrl': thumbnailUrl,
        if (category != null && category!.isNotEmpty) 'category': category,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'organizationId': organizationId,
        'branchId': branchId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
