import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

class PlayerProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<PlayerModel> _players = [];
  PlayerModel? _self;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<PlayerModel>>? _subscription;
  StreamSubscription<PlayerModel?>? _selfSub;

  List<PlayerModel> get players => _players;
  PlayerModel? get self => _self;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Player: listen to their own PlayerModel document (for stats, position, etc.)
  void listenToSelf(String uid) {
    _selfSub?.cancel();
    _selfSub = _firestoreService.streamPlayerById(uid).listen((player) {
      _self = player;
      notifyListeners();
    });
  }

  /// Admin: listen to ALL players in the organization.
  void listenByOrg(String organizationId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamPlayersByOrg(organizationId).listen((list) {
      _players = list;
      notifyListeners();
    });
  }

  /// Coach: listen to players in a specific branch.
  void listenByBranch(String branchId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamPlayersByBranch(branchId).listen((list) {
      _players = list;
      notifyListeners();
    });
  }

  List<PlayerModel> getByBranch(String branchId) =>
      _players.where((p) => p.branchId == branchId).toList();

  List<PlayerModel> getByCategory(String category) =>
      _players.where((p) => p.category == category).toList();

  Future<bool> createPlayer({
    required String name,
    required String email,
    required String password,
    required int age,
    required String position,
    required int jerseyNumber,
    required String phone,
    required String category,
    required String organizationId,
    required String branchId,
    required String adminUid,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = await _authService.createAccountWithoutSignOut(
        email: email,
        password: password,
      );

      // User doc
      final userDoc = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: AppConstants.rolePlayer,
        organizationId: organizationId,
        branchId: branchId,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserDoc(uid, userDoc.toMap());

      // Player doc
      final playerDoc = PlayerModel(
        uid: uid,
        name: name,
        email: email,
        age: age,
        position: position,
        jerseyNumber: jerseyNumber,
        phone: phone,
        category: category,
        organizationId: organizationId,
        branchId: branchId,
        createdBy: adminUid,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createPlayerDoc(uid, playerDoc.toMap());
      return true;
    } catch (e) {
      log('Error creating player: $e');
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlayer({
    required String uid,
    required String name,
    required int age,
    required String position,
    required int jerseyNumber,
    required String phone,
    required String category,
    required String branchId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.updatePlayerDoc(uid, {
        'name': name,
        'age': age,
        'position': position,
        'jerseyNumber': jerseyNumber,
        'phone': phone,
        'category': category,
        'branchId': branchId,
      });
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePlayer(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.deletePlayer(uid);
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'A player with this email already exists.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'operation-not-allowed':
          return 'Account creation is disabled. Contact support.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again.';
        case 'not-found':
          return 'Player record not found.';
        default:
          return e.message ?? 'A database error occurred. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _selfSub?.cancel();
    super.dispose();
  }
}
