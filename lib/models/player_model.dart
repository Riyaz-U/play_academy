import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerStats {
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;

  const PlayerStats({
    this.pace = 50,
    this.shooting = 50,
    this.passing = 50,
    this.dribbling = 50,
    this.defending = 50,
    this.physical = 50,
  });

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      pace: (map['pace'] as num?)?.toInt() ?? 50,
      shooting: (map['shooting'] as num?)?.toInt() ?? 50,
      passing: (map['passing'] as num?)?.toInt() ?? 50,
      dribbling: (map['dribbling'] as num?)?.toInt() ?? 50,
      defending: (map['defending'] as num?)?.toInt() ?? 50,
      physical: (map['physical'] as num?)?.toInt() ?? 50,
    );
  }

  Map<String, dynamic> toMap() => {
        'pace': pace,
        'shooting': shooting,
        'passing': passing,
        'dribbling': dribbling,
        'defending': defending,
        'physical': physical,
      };

  double get overall =>
      (pace + shooting + passing + dribbling + defending + physical) / 6;

  PlayerStats copyWith({
    int? pace,
    int? shooting,
    int? passing,
    int? dribbling,
    int? defending,
    int? physical,
  }) {
    return PlayerStats(
      pace: pace ?? this.pace,
      shooting: shooting ?? this.shooting,
      passing: passing ?? this.passing,
      dribbling: dribbling ?? this.dribbling,
      defending: defending ?? this.defending,
      physical: physical ?? this.physical,
    );
  }
}

class PlayerHealth {
  final String? height;     // e.g. "175 cm"
  final String? weight;     // e.g. "68 kg"
  final String? bloodGroup; // e.g. "O+"
  final String? allergies;
  final String? medications;

  const PlayerHealth({
    this.height,
    this.weight,
    this.bloodGroup,
    this.allergies,
    this.medications,
  });

  factory PlayerHealth.fromMap(Map<String, dynamic> map) {
    return PlayerHealth(
      height: map['height'] as String?,
      weight: map['weight'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      allergies: map['allergies'] as String?,
      medications: map['medications'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (allergies != null) 'allergies': allergies,
        if (medications != null) 'medications': medications,
      };

  bool get isEmpty =>
      height == null &&
      weight == null &&
      bloodGroup == null &&
      allergies == null &&
      medications == null;
}

class PlayerModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String position;
  final int jerseyNumber;
  final String phone;
  final String category;
  final String organizationId;
  final String branchId;
  final String createdBy;
  final DateTime createdAt;
  final PlayerStats stats;
  // Parent contact
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  // Health
  final PlayerHealth health;
  // Bio / notes
  final String? bio;

  const PlayerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.position,
    required this.jerseyNumber,
    required this.phone,
    required this.category,
    required this.organizationId,
    required this.branchId,
    required this.createdBy,
    required this.createdAt,
    this.stats = const PlayerStats(),
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.health = const PlayerHealth(),
    this.bio,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map, String uid) {
    return PlayerModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      position: map['position'] as String? ?? 'Forward',
      jerseyNumber: (map['jerseyNumber'] as num?)?.toInt() ?? 0,
      phone: map['phone'] as String? ?? '',
      category: map['category'] as String? ?? 'Senior',
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      stats: map['stats'] != null
          ? PlayerStats.fromMap(map['stats'] as Map<String, dynamic>)
          : const PlayerStats(),
      parentName: map['parentName'] as String?,
      parentPhone: map['parentPhone'] as String?,
      parentEmail: map['parentEmail'] as String?,
      health: map['health'] != null
          ? PlayerHealth.fromMap(map['health'] as Map<String, dynamic>)
          : const PlayerHealth(),
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'position': position,
      'jerseyNumber': jerseyNumber,
      'phone': phone,
      'category': category,
      'organizationId': organizationId,
      'branchId': branchId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'stats': stats.toMap(),
      if (parentName != null && parentName!.isNotEmpty) 'parentName': parentName,
      if (parentPhone != null && parentPhone!.isNotEmpty) 'parentPhone': parentPhone,
      if (parentEmail != null && parentEmail!.isNotEmpty) 'parentEmail': parentEmail,
      if (!health.isEmpty) 'health': health.toMap(),
      if (bio != null && bio!.isNotEmpty) 'bio': bio,
    };
  }
}
