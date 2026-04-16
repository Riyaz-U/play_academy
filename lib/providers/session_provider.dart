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

  Future<bool> createSession({
    required String title,
    required String type,
    required DateTime dateTime,
    required String location,
    required String notes,
    String? category,
    required String organizationId,
    required String branchId,
    required String coachUid,
    required String coachName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final session = SessionModel(
        id: '',
        title: title,
        type: type,
        dateTime: dateTime,
        location: location,
        notes: notes,
        category: category,
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
