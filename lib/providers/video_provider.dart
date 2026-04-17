import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/video_analysis_model.dart';
import '../services/firestore_service.dart';

class VideoProvider extends ChangeNotifier {
  final FirestoreService _firestore;

  List<VideoAnalysisModel> _videos = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<VideoAnalysisModel>>? _sub;

  List<VideoAnalysisModel> get videos => _videos;
  bool get loading => _loading;
  String? get error => _error;

  VideoProvider(this._firestore);

  void listenByBranch(String branchId) {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();
    _sub = _firestore.streamVideoAnalysisByBranch(branchId).listen(
      (list) {
        _videos = list;
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

  Future<String> addVideo(Map<String, dynamic> data) =>
      _firestore.createVideoAnalysis(data);

  Future<void> deleteVideo(String id) =>
      _firestore.deleteVideoAnalysis(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
