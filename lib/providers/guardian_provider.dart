import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/guardian_model.dart';
import '../models/player_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

class GuardianProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final AuthService _authService = AuthService();

  // ── Admin side ────────────────────────────────────────
  List<GuardianModel> _guardians = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<GuardianModel>>? _adminSubscription;

  List<GuardianModel> get guardians => _guardians;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenByOrg(String organizationId) {
    _adminSubscription?.cancel();
    _adminSubscription =
        _service.streamGuardians(organizationId).listen((list) {
      _guardians = list;
      notifyListeners();
    });
  }

  Future<bool> createGuardian({
    required String name,
    required String email,
    required String phone,
    required String organizationId,
    required String adminUid,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = await _authService.createAccountWithoutSignOut(
        email: email,
        password: const Uuid().v4(),
      );

      final userDoc = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: AppConstants.roleGuardian,
        organizationId: organizationId,
        createdAt: DateTime.now(),
      );
      await _service.createUserDoc(uid, userDoc.toMap());

      final guardianDoc = GuardianModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        organizationId: organizationId,
        createdBy: adminUid,
        createdAt: DateTime.now(),
      );
      await _service.createGuardianDoc(uid, guardianDoc.toMap());
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGuardian({
    required String uid,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateGuardianDoc(uid, {'name': name, 'phone': phone});
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGuardian(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteGuardian(uid);
      return true;
    } catch (e) {
      log('Error deleting guardian: $e');
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setActive(String uid, bool isActive) async {
    try {
      await _service.setGuardianActive(uid, isActive);
      return true;
    } catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  String _mapError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  // ── Player-shell side ─────────────────────────────────
  List<PlayerModel> _children = [];
  PlayerModel? _selectedChild;
  StreamSubscription? _subscription;

  List<PlayerModel> get children => _children;
  PlayerModel? get selectedChild => _selectedChild;

  bool get hasMultipleChildren => _children.length > 1;
  bool get hasChildren => _children.isNotEmpty;

  void listen(String guardianUid) {
    _subscription?.cancel();
    _subscription =
        _service.streamPlayersByGuardian(guardianUid).listen((list) {
      _children = list;
      // Keep selected child in sync; auto-select if only one child
      if (_selectedChild != null) {
        _selectedChild = list.where((p) => p.uid == _selectedChild!.uid).firstOrNull;
      }
      if (_selectedChild == null && list.isNotEmpty) {
        _selectedChild = list.first;
      }
      notifyListeners();
    });
  }

  void selectChild(PlayerModel child) {
    _selectedChild = child;
    notifyListeners();
  }

  void clear() {
    _subscription?.cancel();
    _children = [];
    _selectedChild = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _adminSubscription?.cancel();
    super.dispose();
  }
}
