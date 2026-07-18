class AppConstants {
  // ── Firestore Collections ─────────────────────────────
  static const String organizationsCollection = 'organizations';
  static const String branchesCollection = 'branches';
  static const String usersCollection = 'users';
  static const String coachesCollection = 'coaches';
  static const String playersCollection = 'players';
  static const String sessionsCollection = 'sessions';
  static const String attendanceCollection = 'attendance';
  static const String paymentsCollection = 'payments';
  static const String statsHistoryCollection = 'statsHistory';
  static const String badgesCollection = 'badges';
  static const String drillsCollection = 'drills';
  static const String qrSessionsCollection = 'qrSessions';
  static const String sportProfilesCollection = 'sportProfiles';
  static const String batchesCollection = 'batches';
  static const String guardiansCollection = 'guardians';

  // ── Roles ─────────────────────────────────────────────
  static const String roleOrgAdmin = 'org_admin';
  static const String roleCoach = 'coach';
  static const String rolePlayer = 'player';
  static const String roleGuardian = 'guardian';

  // ── Session types ─────────────────────────────────────
  static const String sessionTypeTraining = 'training';
  static const String sessionTypeMatch = 'match';

  // ── Attendance statuses ───────────────────────────────
  static const String attendancePresent = 'present';
  static const String attendanceAbsent = 'absent';
  static const String attendanceLate = 'late';

  // ── Payment statuses ──────────────────────────────────
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentOverdue = 'overdue';

  // ── FCM ───────────────────────────────────────────────
  static const String fcmChannelId = 'play_academy_channel';
  static const String topicAllPlayers = 'all_players';

  // ── Sports ────────────────────────────────────────────
  static const List<String> sports = [
    'football',
    'basketball',
    'cricket',
    'tennis',
    'volleyball',
    'badminton',
  ];

  // ── Sport-specific positions ──────────────────────────
  static const Map<String, List<String>> sportPositions = {
    'football':   ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'],
    'basketball': ['Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'],
    'cricket':    ['Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper'],
    'tennis':     ['Singles', 'Doubles'],
    'volleyball': ['Setter', 'Libero', 'Outside Hitter', 'Middle Blocker', 'Opposite', 'Serving Specialist'],
    'badminton':  ['Singles', 'Doubles', 'Mixed Doubles'],
  };

  // ── Sport-specific stat keys ──────────────────────────
  static const Map<String, List<String>> sportStats = {
    'football':   ['pace', 'shooting', 'passing', 'dribbling', 'defending', 'physical'],
    'basketball': ['speed', 'shooting', 'passing', 'dribbling', 'defense', 'rebounding'],
    'cricket':    ['batting', 'bowling', 'fielding', 'fitness'],
    'tennis':     ['serve', 'forehand', 'backhand', 'footwork', 'mental'],
    'volleyball': ['serving', 'spiking', 'blocking', 'setting', 'digging', 'fitness'],
    'badminton':  ['smash', 'defense', 'footwork', 'stamina', 'mental'],
  };

  // ── Player age categories ─────────────────────────────
  static const List<String> categories = [
    'U13',
    'U15',
    'U17',
    'U18',
    'U19',
    'U21',
    'Senior',
  ];

  // Max age (inclusive) per category; null = no upper limit (Senior).
  static const Map<String, int?> categoryMaxAge = {
    'U13': 13,
    'U15': 15,
    'U17': 17,
    'U18': 18,
    'U19': 19,
    'U21': 21,
    'Senior': null,
  };

  static bool isCategoryValidForAge(String category, int age) {
    final max = categoryMaxAge[category];
    return max == null || age <= max;
  }

  // ── Razorpay ─────────────────────────────────────────
  // Replace with your actual Razorpay Key ID from the dashboard
  static const String razorpayKeyId = 'rzp_test_XXXXXXXXXXXXXXXX';
}
