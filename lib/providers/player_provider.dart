import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player_model.dart';
import '../models/sport_profile_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

class PlayerProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<PlayerModel> _players = [];
  List<SportProfileModel> _orgSportProfiles = [];
  List<SportProfileModel> _selfSportProfiles = [];
  PlayerModel? _self;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<PlayerModel>>? _subscription;
  StreamSubscription<List<SportProfileModel>>? _sportSub;
  StreamSubscription<List<SportProfileModel>>? _selfSportSub;
  StreamSubscription<PlayerModel?>? _selfSub;

  List<PlayerModel> get players => _players;
  PlayerModel? get self => _self;
  List<SportProfileModel> get selfSportProfiles => _selfSportProfiles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, int> get playersBySport {
    final map = <String, int>{};
    for (final p in _orgSportProfiles) {
      if (p.sport.isNotEmpty) map[p.sport] = (map[p.sport] ?? 0) + 1;
    }
    return map;
  }

  Set<String> playerIdsInBatches(List<String> batchIds) {
    if (batchIds.isEmpty) return {};
    return _orgSportProfiles
        .where((p) => batchIds.contains(p.batchId) && p.playerId.isNotEmpty)
        .map((p) => p.playerId)
        .toSet();
  }

  void listenToSelf(String uid) {
    _selfSub?.cancel();
    _selfSub = _firestoreService.streamPlayerById(uid).listen((player) {
      _self = player;
      notifyListeners();
    });
    _selfSportSub?.cancel();
    _selfSportSub =
        _firestoreService.streamSportProfiles(uid).listen((profiles) {
      _selfSportProfiles = profiles;
      notifyListeners();
    });
  }

  void listenByOrg(String organizationId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamPlayersByOrg(organizationId).listen((list) {
      _players = list;
      notifyListeners();
    });
    _sportSub?.cancel();
    _sportSub = _firestoreService
        .streamAllSportProfilesByOrg(organizationId)
        .listen((list) {
      _orgSportProfiles = list;
      notifyListeners();
    });
  }

  void listenByBranch(String branchId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamPlayersByBranch(branchId).listen((list) {
      _players = list;
      notifyListeners();
    });
  }

  void listenByGuardian(String guardianUid) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamPlayersByGuardian(guardianUid).listen((list) {
      _players = list;
      notifyListeners();
    });
  }

  List<PlayerModel> getByBranch(String branchId) =>
      _players.where((p) => p.branchId == branchId).toList();

  Future<bool> createPlayer({
    required String name,
    required String email,
    required String password,
    required int age,
    required String phone,
    required String organizationId,
    required String branchId,
    required String adminUid,
    required List<SportProfileModel> sportProfiles,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? bio,
    PlayerHealth health = const PlayerHealth(),
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = await _authService.createAccountWithoutSignOut(
        email: email,
        password: password,
      );

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

      final playerDoc = PlayerModel(
        uid: uid,
        name: name,
        email: email,
        age: age,
        phone: phone,
        organizationId: organizationId,
        branchId: branchId,
        createdBy: adminUid,
        createdAt: DateTime.now(),
        parentName: parentName,
        parentPhone: parentPhone,
        parentEmail: parentEmail,
        bio: bio,
        health: health,
      );
      await _firestoreService.createPlayerDoc(uid, playerDoc.toMap());

      for (final profile in sportProfiles) {
        await _firestoreService.createSportProfile(uid, profile.sport,
            profile.copyWith(organizationId: organizationId).toMap());
      }

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
    required String phone,
    required String branchId,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? bio,
    PlayerHealth health = const PlayerHealth(),
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.updatePlayerDoc(uid, {
        'name': name,
        'age': age,
        'phone': phone,
        'branchId': branchId,
        'parentName': parentName,
        'parentPhone': parentPhone,
        'parentEmail': parentEmail,
        'bio': bio,
        if (!health.isEmpty) 'health': health.toMap() else 'health': null,
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

  Future<bool> addSportProfile(
      String playerId, SportProfileModel profile) async {
    try {
      await _firestoreService.createSportProfile(
          playerId, profile.sport, profile.toMap());
      return true;
    } catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSportProfile(
      String playerId, SportProfileModel profile) async {
    try {
      await _firestoreService.updateSportProfile(
          playerId, profile.sport, profile.toMap());
      return true;
    } catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSportProfile(String playerId, String sport) async {
    try {
      await _firestoreService.deleteSportProfile(playerId, sport);
      return true;
    } catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
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

  Future<bool> setActive(String uid, bool isActive) async {
    try {
      await _firestoreService.setPlayerActive(uid, isActive);
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
    _sportSub?.cancel();
    _selfSub?.cancel();
    _selfSportSub?.cancel();
    super.dispose();
  }
}
