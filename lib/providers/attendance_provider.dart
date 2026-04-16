import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../models/player_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

class _PlayerEntry {
  String status;
  int? rating;
  String? ratingNote;
  _PlayerEntry(this.status);
}

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Current session being marked: playerId → entry
  Map<String, _PlayerEntry> _entries = {};
  List<AttendanceModel> _sessionAttendance = [];
  List<AttendanceModel> _playerAttendance = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<AttendanceModel>>? _sessionSub;
  StreamSubscription<List<AttendanceModel>>? _playerSub;

  List<AttendanceModel> get sessionAttendance => _sessionAttendance;
  List<AttendanceModel> get playerAttendance => _playerAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String getStatus(String playerId) =>
      _entries[playerId]?.status ?? AppConstants.attendanceAbsent;

  int? getRating(String playerId) => _entries[playerId]?.rating;

  String? getRatingNote(String playerId) => _entries[playerId]?.ratingNote;

  /// Call this before opening the mark-attendance screen.
  void initForSession(
      List<PlayerModel> players, List<AttendanceModel> existing) {
    _entries = {};
    for (final player in players) {
      final record = existing
          .where((a) => a.playerId == player.uid)
          .toList();
      if (record.isNotEmpty) {
        final e = _PlayerEntry(record.first.status);
        e.rating = record.first.rating;
        e.ratingNote = record.first.ratingNote;
        _entries[player.uid] = e;
      } else {
        _entries[player.uid] = _PlayerEntry(AppConstants.attendanceAbsent);
      }
    }
    notifyListeners();
  }

  void updateStatus(String playerId, String status) {
    _entries.putIfAbsent(playerId, () => _PlayerEntry(status)).status = status;
    notifyListeners();
  }

  void updateRating(String playerId, int rating) {
    _entries.putIfAbsent(
        playerId, () => _PlayerEntry(AppConstants.attendanceAbsent)).rating =
        rating;
    notifyListeners();
  }

  void updateRatingNote(String playerId, String note) {
    _entries
        .putIfAbsent(
            playerId, () => _PlayerEntry(AppConstants.attendanceAbsent))
        .ratingNote = note;
    notifyListeners();
  }

  Future<bool> saveAttendance({
    required String sessionId,
    required String coachUid,
    required String coachName,
    required String organizationId,
    required String branchId,
    required List<PlayerModel> players,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final records = players.map((player) {
        final entry = _entries[player.uid] ??
            _PlayerEntry(AppConstants.attendanceAbsent);
        return AttendanceModel(
          id: '${sessionId}_${player.uid}',
          sessionId: sessionId,
          playerId: player.uid,
          playerName: player.name,
          status: entry.status,
          rating: entry.rating,
          ratingNote: entry.ratingNote,
          markedBy: coachUid,
          markedByName: coachName,
          markedAt: DateTime.now(),
          organizationId: organizationId,
          branchId: branchId,
        );
      }).toList();
      await _firestoreService.saveAttendanceBatch(records);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToSessionAttendance(String sessionId) {
    _sessionSub?.cancel();
    _sessionSub =
        _firestoreService.streamSessionAttendance(sessionId).listen((list) {
      _sessionAttendance = list;
      notifyListeners();
    });
  }

  void listenToPlayerAttendance(String playerId) {
    _playerSub?.cancel();
    _playerSub =
        _firestoreService.streamPlayerAttendance(playerId).listen((list) {
      _playerAttendance = list;
      notifyListeners();
    });
  }

  double get attendancePercentage {
    if (_playerAttendance.isEmpty) return 0;
    final attended =
        _playerAttendance.where((a) => a.attended).length;
    return (attended / _playerAttendance.length) * 100;
  }

  double get averageRating {
    final rated = _playerAttendance
        .where((a) => a.rating != null && a.rating! > 0)
        .toList();
    if (rated.isEmpty) return 0;
    return rated.map((a) => a.rating!).reduce((a, b) => a + b) / rated.length;
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _playerSub?.cancel();
    super.dispose();
  }
}
