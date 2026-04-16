import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

class PlayerProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<PlayerModel> _players = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<PlayerModel>>? _subscription;

  List<PlayerModel> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      _error = e.toString();
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
      // Keep user doc name in sync
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'name': name, 'branchId': branchId});
      return true;
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
