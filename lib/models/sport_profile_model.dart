import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class SportProfileModel {
  final String sport;
  final String branchId;
  final String category;
  final String position;
  final int jerseyNumber;
  final Map<String, int> stats;
  final DateTime enrolledAt;

  const SportProfileModel({
    required this.sport,
    required this.branchId,
    required this.category,
    required this.position,
    required this.jerseyNumber,
    required this.stats,
    required this.enrolledAt,
  });

  double get overall {
    if (stats.isEmpty) return 0;
    return stats.values.reduce((a, b) => a + b) / stats.length;
  }

  static Map<String, int> defaultStats(String sport) {
    final keys = AppConstants.sportStats[sport] ?? [];
    return {for (final k in keys) k: 50};
  }

  factory SportProfileModel.fromMap(Map<String, dynamic> map) {
    final rawStats = map['stats'] as Map<String, dynamic>? ?? {};
    return SportProfileModel(
      sport: map['sport'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      category: map['category'] as String? ?? 'Senior',
      position: map['position'] as String? ?? '',
      jerseyNumber: (map['jerseyNumber'] as num?)?.toInt() ?? 0,
      stats: rawStats.map((k, v) => MapEntry(k, (v as num).toInt())),
      enrolledAt: map['enrolledAt'] != null
          ? (map['enrolledAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'sport': sport,
        'branchId': branchId,
        'category': category,
        'position': position,
        'jerseyNumber': jerseyNumber,
        'stats': stats,
        'enrolledAt': Timestamp.fromDate(enrolledAt),
      };

  SportProfileModel copyWith({
    String? sport,
    String? branchId,
    String? category,
    String? position,
    int? jerseyNumber,
    Map<String, int>? stats,
    DateTime? enrolledAt,
  }) {
    return SportProfileModel(
      sport: sport ?? this.sport,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      position: position ?? this.position,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      stats: stats ?? this.stats,
      enrolledAt: enrolledAt ?? this.enrolledAt,
    );
  }
}
