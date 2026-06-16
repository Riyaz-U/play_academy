import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/drill_model.dart';
import '../services/firestore_service.dart';

class DrillProvider extends ChangeNotifier {
  final FirestoreService _firestore;

  List<DrillModel> _drills = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<DrillModel>>? _sub;

  List<DrillModel> get drills => _drills;
  bool get loading => _loading;
  String? get error => _error;

  DrillProvider(this._firestore);

  void listenByBranch(String branchId) {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();
    _sub = _firestore.streamDrillsByBranch(branchId).listen(
      (list) {
        _drills = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  List<DrillModel> getBySport(String sport) =>
      _drills.where((d) => d.sport == sport).toList();

  Future<void> addDrill(Map<String, dynamic> data) =>
      _firestore.createDrill(data);

  Future<void> updateDrill(String id, Map<String, dynamic> data) =>
      _firestore.updateDrill(id, data);

  Future<void> deleteDrill(String id) => _firestore.deleteDrill(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
