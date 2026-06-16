import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMemberModel {
  final String playerId;
  final String playerName;
  final String addedBy;
  final DateTime addedAt;

  const TeamMemberModel({
    required this.playerId,
    required this.playerName,
    required this.addedBy,
    required this.addedAt,
  });

  factory TeamMemberModel.fromMap(Map<String, dynamic> map) {
    return TeamMemberModel(
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      addedBy: map['addedBy'] as String? ?? '',
      addedAt: map['addedAt'] != null
          ? (map['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'playerName': playerName,
        'addedBy': addedBy,
        'addedAt': Timestamp.fromDate(addedAt),
      };
}
