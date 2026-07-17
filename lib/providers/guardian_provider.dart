import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../services/firestore_service.dart';

class GuardianProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

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
    super.dispose();
  }
}
