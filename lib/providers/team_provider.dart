import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/team_model.dart';
import '../models/team_member_model.dart';
import '../models/player_model.dart';
import '../services/firestore_service.dart';

class TeamProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<TeamModel> _teams = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<TeamModel>>? _subscription;

  List<TeamModel> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TeamModel> getByBranch(String branchId) =>
      _teams.where((t) => t.branchId == branchId).toList();

  List<TeamModel> getBySport(String sport) =>
      _teams.where((t) => t.sport == sport).toList();

  TeamModel? getById(String id) {
    try {
      return _teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void listenByBranch(String branchId) {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _subscription = _firestore.streamTeamsByBranch(branchId).listen(
      (list) {
        _teams = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> createTeam({
    required String name,
    required String sport,
    required String branchId,
    required String organizationId,
    required String createdBy,
    List<PlayerModel> members = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final team = TeamModel(
        id: '',
        name: name,
        sport: sport,
        branchId: branchId,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      final teamId = await _firestore.createTeam(team.toMap());
      for (final player in members) {
        await _firestore.addTeamMember(
          teamId,
          player.uid,
          TeamMemberModel(
            playerId: player.uid,
            playerName: player.name,
            addedBy: createdBy,
            addedAt: DateTime.now(),
          ).toMap(),
        );
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTeam(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.updateTeam(id, data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTeam(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.deleteTeam(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMember(
      String teamId, PlayerModel player, String addedBy) async {
    try {
      await _firestore.addTeamMember(
        teamId,
        player.uid,
        TeamMemberModel(
          playerId: player.uid,
          playerName: player.name,
          addedBy: addedBy,
          addedAt: DateTime.now(),
        ).toMap(),
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(String teamId, String playerId) async {
    try {
      await _firestore.removeTeamMember(teamId, playerId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Stream<List<TeamMemberModel>> streamMembers(String teamId) =>
      _firestore.streamTeamMembers(teamId);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
