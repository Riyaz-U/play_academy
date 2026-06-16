import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeModel {
  final String id;
  final String playerId;
  final String name;
  final String emoji;
  final String? sport;
  final String? note;
  final String awardedBy;
  final String awardedByName;
  final DateTime awardedAt;

  const BadgeModel({
    required this.id,
    required this.playerId,
    required this.name,
    required this.emoji,
    this.sport,
    this.note,
    required this.awardedBy,
    required this.awardedByName,
    required this.awardedAt,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map, String id) {
    final name = map['name'] as String? ?? '';
    final storedEmoji = map['emoji'] as String?;
    final fallbackEmoji = BadgeType.all
            .where((bt) => bt.name == name)
            .map((bt) => bt.emoji)
            .firstOrNull ??
        '🏅';
    return BadgeModel(
      id: id,
      playerId: map['playerId'] as String? ?? '',
      name: name,
      emoji: storedEmoji ?? fallbackEmoji,
      sport: map['sport'] as String?,
      note: map['note'] as String?,
      awardedBy: map['awardedBy'] as String? ?? '',
      awardedByName: map['awardedByName'] as String? ?? '',
      awardedAt: map['awardedAt'] != null
          ? (map['awardedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'name': name,
        'emoji': emoji,
        if (sport != null) 'sport': sport,
        if (note != null && note!.isNotEmpty) 'note': note,
        'awardedBy': awardedBy,
        'awardedByName': awardedByName,
        'awardedAt': Timestamp.fromDate(awardedAt),
      };
}

class BadgeType {
  final String name;
  final String emoji;

  const BadgeType({required this.name, required this.emoji});

  static const List<BadgeType> all = [
    BadgeType(name: 'Most Improved', emoji: '📈'),
    BadgeType(name: 'Speed Demon', emoji: '⚡'),
    BadgeType(name: 'Playmaker', emoji: '🎯'),
    BadgeType(name: 'Hard Worker', emoji: '💪'),
    BadgeType(name: 'Team Player', emoji: '🤝'),
    BadgeType(name: 'Rising Star', emoji: '🌟'),
    BadgeType(name: 'Iron Man', emoji: '🏃'),
    BadgeType(name: 'Best Attendance', emoji: '📅'),
    BadgeType(name: 'Top Performer', emoji: '🏆'),
    BadgeType(name: 'Leadership', emoji: '🦁'),
    BadgeType(name: 'Comeback Kid', emoji: '🔥'),
  ];
}
