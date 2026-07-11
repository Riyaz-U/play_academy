import 'dart:async';
import 'package:flutter/material.dart';
import '../models/batch_model.dart';
import '../services/firestore_service.dart';

class BatchProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<BatchModel> _batches = [];
  StreamSubscription? _subscription;

  List<BatchModel> get batches => _batches;

  List<BatchModel> batchesBySport(String sport) =>
      _batches.where((b) => b.sport == sport).toList();

  List<BatchModel> batchesByCategory(String category) =>
      _batches.where((b) => b.category == category).toList();

  // For coaches: only their assigned batches
  void listenByCoach(String coachUid) {
    _subscription?.cancel();
    _subscription = _service.streamBatchesByCoach(coachUid).listen((list) {
      _batches = list;
      notifyListeners();
    });
  }

  // For org admins: all batches in the org
  void listenByOrg(String organizationId) {
    _subscription?.cancel();
    _subscription =
        _service.streamBatchesByOrg(organizationId).listen((list) {
      _batches = list;
      notifyListeners();
    });
  }

  // Branch-level stream (retained for internal use if needed)
  void listenByBranch(String branchId) {
    _subscription?.cancel();
    _subscription = _service.streamBatchesByBranch(branchId).listen((list) {
      _batches = list;
      notifyListeners();
    });
  }

  Future<String> createBatch({
    required String name,
    required String sport,
    required String category,
    required String branchId,
    required String organizationId,
    required String createdBy,
    List<String> coachIds = const [],
  }) async {
    final data = BatchModel(
      id: '',
      name: name,
      sport: sport,
      category: category,
      branchId: branchId,
      organizationId: organizationId,
      createdBy: createdBy,
      coachIds: coachIds,
      createdAt: DateTime.now(),
    ).toMap();
    return _service.createBatch(data);
  }

  Future<void> updateBatch(
    String id, {
    String? name,
    List<String>? coachIds,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (coachIds != null) data['coachIds'] = coachIds;
    if (data.isNotEmpty) await _service.updateBatch(id, data);
  }

  Future<void> deleteBatch(String id) async {
    await _service.deleteBatch(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
