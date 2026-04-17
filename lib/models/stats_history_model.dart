import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

class StatsHistoryModel {
  final String id;
  final String playerId;
  final PlayerStats stats;
  final String? note;
  final DateTime recordedAt;

  const StatsHistoryModel({
    required this.id,
    required this.playerId,
    required this.stats,
    this.note,
    required this.recordedAt,
  });

  factory StatsHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StatsHistoryModel(
      id: id,
      playerId: map['playerId'] as String? ?? '',
      stats: map['stats'] != null
          ? PlayerStats.fromMap(map['stats'] as Map<String, dynamic>)
          : const PlayerStats(),
      note: map['note'] as String?,
      recordedAt: map['recordedAt'] != null
          ? (map['recordedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'stats': stats.toMap(),
        if (note != null && note!.isNotEmpty) 'note': note,
        'recordedAt': Timestamp.fromDate(recordedAt),
      };
}
