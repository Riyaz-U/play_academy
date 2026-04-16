import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coach_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

class CoachProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<CoachModel> _coaches = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<CoachModel>>? _subscription;

  List<CoachModel> get coaches => _coaches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenByOrg(String organizationId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamCoaches(organizationId).listen((list) {
      _coaches = list;
      notifyListeners();
    });
  }

  List<CoachModel> getByBranch(String branchId) =>
      _coaches.where((c) => c.branchId == branchId).toList();

  Future<bool> createCoach({
    required String name,
    required String email,
    required String password,
    required String phone,
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

      final userDoc = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: AppConstants.roleCoach,
        organizationId: organizationId,
        branchId: branchId,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserDoc(uid, userDoc.toMap());

      final coachDoc = CoachModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        organizationId: organizationId,
        branchId: branchId,
        createdBy: adminUid,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createCoachDoc(uid, coachDoc.toMap());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCoach({
    required String uid,
    required String name,
    required String phone,
    required String branchId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.updateCoachDoc(uid, {
        'name': name,
        'phone': phone,
        'branchId': branchId,
      });
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

  Future<bool> deleteCoach(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.deleteCoach(uid);
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
