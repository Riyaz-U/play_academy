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

  // ── Roles ─────────────────────────────────────────────
  static const String roleOrgAdmin = 'org_admin';
  static const String roleCoach = 'coach';
  static const String rolePlayer = 'player';

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

  // ── Player positions ──────────────────────────────────
  static const List<String> positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

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

  // ── Razorpay ─────────────────────────────────────────
  // Replace with your actual Razorpay Key ID from the dashboard
  static const String razorpayKeyId = 'rzp_test_XXXXXXXXXXXXXXXX';
}
