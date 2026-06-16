import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../models/dashboard_model.dart';
import '../models/payment_model.dart';
import '../models/player_model.dart';
import '../models/session_model.dart';
import '../models/sport_profile_model.dart';
import '../services/firestore_service.dart';

class DashboardProvider extends ChangeNotifier {
  final FirestoreService _firestore;

  DashboardSummary _summary = DashboardSummary.empty;
  bool _loading = false;
  String? _error;

  DashboardSummary get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;

  StreamSubscription<List<PlayerModel>>? _playersSub;
  StreamSubscription<List<SessionModel>>? _sessionsSub;
  StreamSubscription<List<PaymentModel>>? _paymentsSub;
  StreamSubscription<List<AttendanceModel>>? _attendanceSub;
  StreamSubscription<List<SportProfileModel>>? _sportProfilesSub;

  List<PlayerModel> _players = [];
  List<SessionModel> _sessions = [];
  List<PaymentModel> _payments = [];
  List<AttendanceModel> _attendance = [];
  List<SportProfileModel> _sportProfiles = [];

  Map<String, int> get playersBySport {
    final map = <String, int>{};
    for (final p in _sportProfiles) {
      map[p.sport] = (map[p.sport] ?? 0) + 1;
    }
    return map;
  }

  DashboardProvider(this._firestore);

  void load(String branchId) {
    _loading = true;
    _error = null;
    notifyListeners();

    final since = DateTime.now().subtract(const Duration(days: 30));

    _playersSub?.cancel();
    _sessionsSub?.cancel();
    _paymentsSub?.cancel();
    _attendanceSub?.cancel();
    _sportProfilesSub?.cancel();

    _sportProfilesSub =
        _firestore.streamAllSportProfilesByBranch(branchId).listen((list) {
      _sportProfiles = list;
      _recompute();
    }, onError: _onError);

    _playersSub = _firestore.streamPlayersByBranch(branchId).listen((list) {
      _players = list;
      _recompute();
    }, onError: _onError);

    _sessionsSub =
        _firestore.streamUpcomingSessionsByBranch(branchId).listen((list) {
      _sessions = list;
      _recompute();
    }, onError: _onError);

    _paymentsSub =
        _firestore.streamPaymentsByBranch(branchId).listen((list) {
      _payments = list;
      _recompute();
    }, onError: _onError);

    _attendanceSub = _firestore
        .streamAttendanceByBranch(branchId, since: since)
        .listen((list) {
      _attendance = list;
      _recompute();
    }, onError: _onError);
  }

  void _recompute() {
    _loading = false;
    _summary = DashboardSummary(
      totalPlayers: _players.length,
      upcomingSessions: _sessions.length,
      attendanceRate: _computeAttendanceRate(),
      payments: _computePaymentSummary(),
      weeklyAttendance: _computeWeeklyTrend(),
    );
    notifyListeners();
  }

  double _computeAttendanceRate() {
    if (_attendance.isEmpty) return 0;
    final attended = _attendance.where((a) => a.attended).length;
    return attended / _attendance.length;
  }

  PaymentSummary _computePaymentSummary() {
    int pendingCount = 0, paidCount = 0, overdueCount = 0;
    double pendingAmt = 0, paidAmt = 0, overdueAmt = 0;
    for (final p in _payments) {
      if (p.isPending) {
        pendingCount++;
        pendingAmt += p.amount;
      } else if (p.isPaid) {
        paidCount++;
        paidAmt += p.amount;
      } else if (p.isOverdue) {
        overdueCount++;
        overdueAmt += p.amount;
      }
    }
    return PaymentSummary(
      pendingCount: pendingCount,
      paidCount: paidCount,
      overdueCount: overdueCount,
      pendingAmount: pendingAmt,
      paidAmount: paidAmt,
      overdueAmount: overdueAmt,
    );
  }

  List<AttendanceTrend> _computeWeeklyTrend() {
    final now = DateTime.now();
    // Build a map keyed by date (year-month-day) for the last 7 days.
    final Map<String, AttendanceTrend> map = {};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = _dayKey(day);
      map[key] = AttendanceTrend(date: DateTime(day.year, day.month, day.day));
    }

    for (final record in _attendance) {
      final key = _dayKey(record.markedAt);
      if (!map.containsKey(key)) continue;
      final existing = map[key]!;
      map[key] = existing +
          AttendanceTrend(
            date: existing.date,
            present: record.isPresent ? 1 : 0,
            absent: record.isAbsent ? 1 : 0,
            late: record.isLate ? 1 : 0,
          );
    }
    return map.values.toList();
  }

  String _dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  void _onError(Object e) {
    _loading = false;
    _error = e.toString();
    notifyListeners();
  }

  @override
  void dispose() {
    _playersSub?.cancel();
    _sessionsSub?.cancel();
    _paymentsSub?.cancel();
    _attendanceSub?.cancel();
    _sportProfilesSub?.cancel();
    super.dispose();
  }
}
