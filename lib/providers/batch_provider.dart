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

  void listenByBranch(String branchId) {
    _subscription?.cancel();
    _subscription = _service.streamBatchesByBranch(branchId).listen((list) {
      _batches = list;
      notifyListeners();
    });
  }

  Future<void> createBatch({
    required String name,
    required String sport,
    required String category,
    required String branchId,
    required String organizationId,
    required String createdBy,
  }) async {
    final data = BatchModel(
      id: '',
      name: name,
      sport: sport,
      category: category,
      branchId: branchId,
      organizationId: organizationId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    ).toMap();
    await _service.createBatch(data);
  }

  Future<void> updateBatch(String id, {required String name}) async {
    await _service.updateBatch(id, {'name': name});
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
