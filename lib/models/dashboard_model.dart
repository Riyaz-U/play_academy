// Lightweight value objects used by DashboardProvider to feed chart widgets.

class AttendanceTrend {
  final DateTime date; // truncated to day
  final int present;
  final int absent;
  final int late;

  const AttendanceTrend({
    required this.date,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
  });

  int get total => present + absent + late;
  double get rate => total == 0 ? 0.0 : (present + late) / total;

  AttendanceTrend operator +(AttendanceTrend other) => AttendanceTrend(
        date: date,
        present: present + other.present,
        absent: absent + other.absent,
        late: late + other.late,
      );
}

class PaymentSummary {
  final int pendingCount;
  final int paidCount;
  final int overdueCount;
  final double pendingAmount;
  final double paidAmount;
  final double overdueAmount;

  const PaymentSummary({
    this.pendingCount = 0,
    this.paidCount = 0,
    this.overdueCount = 0,
    this.pendingAmount = 0,
    this.paidAmount = 0,
    this.overdueAmount = 0,
  });

  double get totalDue => pendingAmount + overdueAmount;
  int get totalCount => pendingCount + paidCount + overdueCount;
}

class DashboardSummary {
  final int totalPlayers;
  final int upcomingSessions;
  /// Overall attendance rate (0–1) over the last 30 days.
  final double attendanceRate;
  final PaymentSummary payments;
  /// Daily attendance data for the last 7 days (oldest → newest).
  final List<AttendanceTrend> weeklyAttendance;

  const DashboardSummary({
    this.totalPlayers = 0,
    this.upcomingSessions = 0,
    this.attendanceRate = 0,
    this.payments = const PaymentSummary(),
    this.weeklyAttendance = const [],
  });

  static const empty = DashboardSummary();
}
