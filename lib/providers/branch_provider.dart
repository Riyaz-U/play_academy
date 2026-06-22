import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/branch_model.dart';
import '../services/firestore_service.dart';

class BranchProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<BranchModel> _branches = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<BranchModel>>? _subscription;

  List<BranchModel> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToBranches(String organizationId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamBranches(organizationId).listen((branches) {
      _branches = branches;
      notifyListeners();
    });
  }

  Future<bool> createBranch({
    required String name,
    required String location,
    required String city,
    required String organizationId,
    String country = '',
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final branch = BranchModel(
        id: '',
        name: name,
        location: location,
        city: city,
        organizationId: organizationId,
        country: country,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createBranch(branch.toMap());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBranch({
    required String id,
    required String name,
    required String location,
    required String city,
    String country = '',
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.updateBranch(id, {
        'name': name,
        'location': location,
        'city': city,
        if (country.isNotEmpty) 'country': country else 'country': null,
        if (latitude != null) 'latitude': latitude else 'latitude': null,
        if (longitude != null) 'longitude': longitude else 'longitude': null,
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

  Future<bool> deleteBranch(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.deleteBranch(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setActive(String id, bool isActive) async {
    try {
      await _firestoreService.setBranchActive(id, isActive);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  BranchModel? getBranchById(String id) {
    try {
      return _branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
