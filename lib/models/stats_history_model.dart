import 'package:cloud_firestore/cloud_firestore.dart';

class StatsHistoryModel {
  final String id;
  final String playerId;
  final String sport;
  final Map<String, int> stats;
  final String? note;
  final DateTime recordedAt;

  const StatsHistoryModel({
    required this.id,
    required this.playerId,
    required this.sport,
    required this.stats,
    this.note,
    required this.recordedAt,
  });

  double get overall {
    if (stats.isEmpty) return 0;
    return stats.values.reduce((a, b) => a + b) / stats.length;
  }

  factory StatsHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    final rawStats = map['stats'] as Map<String, dynamic>? ?? {};
    return StatsHistoryModel(
      id: id,
      playerId: map['playerId'] as String? ?? '',
      sport: map['sport'] as String? ?? '',
      stats: rawStats.map((k, v) => MapEntry(k, (v as num).toInt())),
      note: map['note'] as String?,
      recordedAt: map['recordedAt'] != null
          ? (map['recordedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'sport': sport,
        'stats': stats,
        if (note != null && note!.isNotEmpty) 'note': note,
        'recordedAt': Timestamp.fromDate(recordedAt),
      };
}
