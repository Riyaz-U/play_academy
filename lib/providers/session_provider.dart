import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../services/firestore_service.dart';

class SessionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<SessionModel> _sessions = [];
  List<SessionModel> _upcomingSessions = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<SessionModel>>? _allSubscription;
  StreamSubscription<List<SessionModel>>? _upcomingSubscription;

  List<SessionModel> get sessions => _sessions;
  List<SessionModel> get upcomingSessions => _upcomingSessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToSessions(String branchId) {
    _allSubscription?.cancel();
    _allSubscription =
        _firestoreService.streamSessionsByBranch(branchId).listen((list) {
      _sessions = list;
      notifyListeners();
    });
  }

  void listenToUpcoming(String branchId) {
    _upcomingSubscription?.cancel();
    _upcomingSubscription =
        _firestoreService.streamUpcomingSessionsByBranch(branchId).listen(
      (list) {
        _upcomingSessions = list;
        notifyListeners();
      },
    );
  }

  List<SessionModel> getBySport(String sport) =>
      _sessions.where((s) => s.sport == sport).toList();

  List<SessionModel> getByBatch(String batchId) =>
      _sessions.where((s) => s.batchIds.contains(batchId)).toList();

  // Returns the conflicting session title if the new session overlaps an
  // existing session on any shared batch, null if no conflict.
  String? _findBatchConflict({
    required DateTime start,
    required int durationMinutes,
    required List<String> batchIds,
    String? excludeId,
  }) {
    if (batchIds.isEmpty) return null;
    final end = start.add(Duration(minutes: durationMinutes));
    for (final s in _sessions) {
      if (s.id == excludeId || s.isCompleted) continue;
      final sharedBatch = s.batchIds.any((id) => batchIds.contains(id));
      if (!sharedBatch) continue;
      final sEnd = s.endTime;
      if (start.isBefore(sEnd) && end.isAfter(s.dateTime)) {
        return s.title;
      }
    }
    return null;
  }

  Future<bool> createSession({
    required String title,
    required String type,
    required DateTime dateTime,
    required String location,
    required String notes,
    String? sport,
    String? category,
    List<String> batchIds = const [],
    List<String> playerIds = const [],
    int durationMinutes = 90,
    required String organizationId,
    required String branchId,
    required String coachUid,
    required String coachName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final conflict = _findBatchConflict(
        start: dateTime,
        durationMinutes: durationMinutes,
        batchIds: batchIds,
      );
      if (conflict != null) {
        _error = 'Batch already has a session "$conflict" overlapping this time slot.';
        return false;
      }
      final session = SessionModel(
        id: '',
        title: title,
        type: type,
        dateTime: dateTime,
        durationMinutes: durationMinutes,
        location: location,
        notes: notes,
        sport: sport,
        category: category,
        batchIds: batchIds,
        playerIds: playerIds,
        organizationId: organizationId,
        branchId: branchId,
        createdBy: coachUid,
        createdByName: coachName,
        createdAt: DateTime.now(),
        isCompleted: false,
      );
      await _firestoreService.createSession(session.toMap());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeSession({
    required String sessionId,
    required String highlights,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.updateSession(sessionId, {
        'isCompleted': true,
        'highlights': highlights,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSession(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.deleteSession(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  SessionModel? getById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _allSubscription?.cancel();
    _upcomingSubscription?.cancel();
    super.dispose();
  }
}
