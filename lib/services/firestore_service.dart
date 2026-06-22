import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/organization_model.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';
import '../models/coach_model.dart';
import '../models/player_model.dart';
import '../models/stats_history_model.dart';
import '../models/badge_model.dart';
import '../models/drill_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/payment_model.dart';
import '../models/video_analysis_model.dart';
import '../models/qr_session_model.dart';
import '../models/sport_profile_model.dart';
import '../models/team_model.dart';
import '../models/team_member_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  // Connects to the named 'default' database (without parentheses).
  // If your Firestore DB ID is '(default)', change this to:
  // FirebaseFirestore.instance
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  // ── Organizations ──────────────────────────────────────

  Future<void> createOrganization(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.organizationsCollection).doc(id).set(data);

  Future<OrganizationModel?> getOrganization(String id) async {
    final doc =
        await _db.collection(AppConstants.organizationsCollection).doc(id).get();
    if (!doc.exists) return null;
    return OrganizationModel.fromMap(doc.data()!, id);
  }

  // ── Users ──────────────────────────────────────────────

  Future<void> createUserDoc(String uid, Map<String, dynamic> data) =>
      _db.collection(AppConstants.usersCollection).doc(uid).set(data);

  Future<UserModel?> getUserDoc(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 10));
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateFcmToken(String uid, String token) =>
      _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'fcmToken': token});

  Future<void> setOrganizationActive(String orgId, bool isActive) =>
      _db.collection(AppConstants.organizationsCollection).doc(orgId).update({'isActive': isActive});

  Future<void> setBranchActive(String branchId, bool isActive) =>
      _db.collection(AppConstants.branchesCollection).doc(branchId).update({'isActive': isActive});

  Future<void> setCoachActive(String uid, bool isActive) async {
    await _db.collection(AppConstants.coachesCollection).doc(uid).update({'isActive': isActive});
    await _db.collection(AppConstants.usersCollection).doc(uid).update({'isActive': isActive});
  }

  Future<void> setPlayerActive(String uid, bool isActive) async {
    await _db.collection(AppConstants.playersCollection).doc(uid).update({'isActive': isActive});
    await _db.collection(AppConstants.usersCollection).doc(uid).update({'isActive': isActive});
  }

  // ── Branches ───────────────────────────────────────────

  Future<String> createBranch(Map<String, dynamic> data) async {
    final doc =
        await _db.collection(AppConstants.branchesCollection).add(data);
    return doc.id;
  }

  Future<void> updateBranch(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.branchesCollection).doc(id).update(data);

  Future<void> deleteBranch(String id) =>
      _db.collection(AppConstants.branchesCollection).doc(id).delete();

  Stream<List<BranchModel>> streamBranches(String organizationId) =>
      _db
          .collection(AppConstants.branchesCollection)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt')
          .snapshots()
          .map((s) => s.docs
              .map((d) => BranchModel.fromMap(d.data(), d.id))
              .toList());

  Future<List<BranchModel>> getBranches(String organizationId) async {
    final snap = await _db
        .collection(AppConstants.branchesCollection)
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt')
        .get();
    return snap.docs.map((d) => BranchModel.fromMap(d.data(), d.id)).toList();
  }

  // ── Coaches ────────────────────────────────────────────

  Future<void> createCoachDoc(String uid, Map<String, dynamic> data) =>
      _db.collection(AppConstants.coachesCollection).doc(uid).set(data);

  Future<void> updateCoachDoc(String uid, Map<String, dynamic> data) =>
      _db.collection(AppConstants.coachesCollection).doc(uid).update(data);

  Future<void> deleteCoach(String uid) async {
    await _db.collection(AppConstants.coachesCollection).doc(uid).delete();
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }

  Stream<List<CoachModel>> streamCoaches(String organizationId) =>
      _db
          .collection(AppConstants.coachesCollection)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => CoachModel.fromMap(d.data(), d.id))
              .toList());

  Stream<List<CoachModel>> streamCoachesByBranch(String branchId) =>
      _db
          .collection(AppConstants.coachesCollection)
          .where('branchId', isEqualTo: branchId)
          .snapshots()
          .map((s) => s.docs
              .map((d) => CoachModel.fromMap(d.data(), d.id))
              .toList());

  // ── Players ────────────────────────────────────────────

  Future<void> createPlayerDoc(String uid, Map<String, dynamic> data) =>
      _db.collection(AppConstants.playersCollection).doc(uid).set(data);

  Future<void> updatePlayerDoc(String uid, Map<String, dynamic> data) =>
      _db.collection(AppConstants.playersCollection).doc(uid).update(data);

  // ── Stats History (subcollection of players) ───────────
  Future<void> addStatsHistory(
      String playerId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.playersCollection)
        .doc(playerId)
        .collection(AppConstants.statsHistoryCollection)
        .add(data);
  }

  Stream<List<StatsHistoryModel>> streamStatsHistory(String playerId) => _db
      .collection(AppConstants.playersCollection)
      .doc(playerId)
      .collection(AppConstants.statsHistoryCollection)
      .orderBy('recordedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => StatsHistoryModel.fromMap(d.data(), d.id))
          .toList());

  Future<void> deleteStatsHistory(String playerId, String entryId) => _db
      .collection(AppConstants.playersCollection)
      .doc(playerId)
      .collection(AppConstants.statsHistoryCollection)
      .doc(entryId)
      .delete();

  // ── Badges (subcollection of players) ──────────────────
  Future<void> awardBadge(String playerId, Map<String, dynamic> data) => _db
      .collection(AppConstants.playersCollection)
      .doc(playerId)
      .collection(AppConstants.badgesCollection)
      .add(data);

  Stream<List<BadgeModel>> streamBadges(String playerId) => _db
      .collection(AppConstants.playersCollection)
      .doc(playerId)
      .collection(AppConstants.badgesCollection)
      .orderBy('awardedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => BadgeModel.fromMap(d.data(), d.id))
          .toList());

  Future<void> deleteBadge(String playerId, String badgeId) => _db
      .collection(AppConstants.playersCollection)
      .doc(playerId)
      .collection(AppConstants.badgesCollection)
      .doc(badgeId)
      .delete();

  // ── Drills ─────────────────────────────────────────────
  Future<String> createDrill(Map<String, dynamic> data) async {
    final doc = await _db.collection(AppConstants.drillsCollection).add(data);
    return doc.id;
  }

  Future<void> updateDrill(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.drillsCollection).doc(id).update(data);

  Future<void> deleteDrill(String id) =>
      _db.collection(AppConstants.drillsCollection).doc(id).delete();

  Stream<List<DrillModel>> streamDrillsByBranch(String branchId) => _db
      .collection(AppConstants.drillsCollection)
      .where('branchId', isEqualTo: branchId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DrillModel.fromMap(d.data(), d.id)).toList());

  Future<void> deletePlayer(String uid) async {
    // Delete sport profiles subcollection first
    final profiles = await _db
        .collection(AppConstants.playersCollection)
        .doc(uid)
        .collection(AppConstants.sportProfilesCollection)
        .get();
    final batch = _db.batch();
    for (final doc in profiles.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection(AppConstants.playersCollection).doc(uid));
    batch.delete(_db.collection(AppConstants.usersCollection).doc(uid));
    await batch.commit();
  }

  // ── Sport Profiles (subcollection of players) ──────────

  Future<void> createSportProfile(
          String playerId, String sport, Map<String, dynamic> data) =>
      _db
          .collection(AppConstants.playersCollection)
          .doc(playerId)
          .collection(AppConstants.sportProfilesCollection)
          .doc(sport)
          .set(data);

  Future<void> updateSportProfile(
          String playerId, String sport, Map<String, dynamic> data) =>
      _db
          .collection(AppConstants.playersCollection)
          .doc(playerId)
          .collection(AppConstants.sportProfilesCollection)
          .doc(sport)
          .update(data);

  Future<void> deleteSportProfile(String playerId, String sport) =>
      _db
          .collection(AppConstants.playersCollection)
          .doc(playerId)
          .collection(AppConstants.sportProfilesCollection)
          .doc(sport)
          .delete();

  Stream<List<SportProfileModel>> streamSportProfiles(String playerId) =>
      _db
          .collection(AppConstants.playersCollection)
          .doc(playerId)
          .collection(AppConstants.sportProfilesCollection)
          .snapshots()
          .map((s) => s.docs
              .map((d) =>
                  SportProfileModel.fromMap(d.data(), playerId: playerId))
              .toList());

  Future<SportProfileModel?> getSportProfile(
      String playerId, String sport) async {
    final doc = await _db
        .collection(AppConstants.playersCollection)
        .doc(playerId)
        .collection(AppConstants.sportProfilesCollection)
        .doc(sport)
        .get();
    if (!doc.exists) return null;
    return SportProfileModel.fromMap(doc.data()!);
  }

  Stream<List<SportProfileModel>> streamSportProfilesByBranch(
          String branchId, String sport) =>
      _db
          .collectionGroup(AppConstants.sportProfilesCollection)
          .where('branchId', isEqualTo: branchId)
          .where('sport', isEqualTo: sport)
          .snapshots()
          .map((s) => s.docs
              .map((d) => SportProfileModel.fromMap(d.data(),
                  playerId: d.reference.parent.parent?.id ?? ''))
              .toList());

  Stream<List<SportProfileModel>> streamAllSportProfilesByBranch(
          String branchId) =>
      _db
          .collectionGroup(AppConstants.sportProfilesCollection)
          .where('branchId', isEqualTo: branchId)
          .snapshots()
          .map((s) => s.docs
              .map((d) => SportProfileModel.fromMap(d.data(),
                  playerId: d.reference.parent.parent?.id ?? ''))
              .toList());

  Stream<List<SportProfileModel>> streamAllSportProfilesByOrg(
          String organizationId) =>
      _db
          .collectionGroup(AppConstants.sportProfilesCollection)
          .where('organizationId', isEqualTo: organizationId)
          .snapshots()
          .map((s) => s.docs
              .map((d) => SportProfileModel.fromMap(d.data(),
                  playerId: d.reference.parent.parent?.id ?? ''))
              .toList());

  // ── Teams ──────────────────────────────────────────────

  Future<String> createTeam(Map<String, dynamic> data) async {
    final doc = await _db.collection(AppConstants.teamsCollection).add(data);
    return doc.id;
  }

  Future<void> updateTeam(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.teamsCollection).doc(id).update(data);

  Future<void> deleteTeam(String id) =>
      _db.collection(AppConstants.teamsCollection).doc(id).delete();

  Stream<List<TeamModel>> streamTeamsByBranch(String branchId) =>
      _db
          .collection(AppConstants.teamsCollection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => TeamModel.fromMap(d.data(), d.id)).toList());

  Stream<List<TeamModel>> streamTeamsBySport(
          String branchId, String sport) =>
      _db
          .collection(AppConstants.teamsCollection)
          .where('branchId', isEqualTo: branchId)
          .where('sport', isEqualTo: sport)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => TeamModel.fromMap(d.data(), d.id)).toList());

  // ── Team Members (subcollection of teams) ──────────────

  Future<void> addTeamMember(
          String teamId, String playerId, Map<String, dynamic> data) =>
      _db
          .collection(AppConstants.teamsCollection)
          .doc(teamId)
          .collection(AppConstants.teamMembersCollection)
          .doc(playerId)
          .set(data);

  Future<void> removeTeamMember(String teamId, String playerId) =>
      _db
          .collection(AppConstants.teamsCollection)
          .doc(teamId)
          .collection(AppConstants.teamMembersCollection)
          .doc(playerId)
          .delete();

  Stream<List<TeamMemberModel>> streamTeamMembers(String teamId) =>
      _db
          .collection(AppConstants.teamsCollection)
          .doc(teamId)
          .collection(AppConstants.teamMembersCollection)
          .orderBy('addedAt')
          .snapshots()
          .map((s) => s.docs
              .map((d) => TeamMemberModel.fromMap(d.data()))
              .toList());

  Stream<PlayerModel?> streamPlayerById(String uid) =>
      _db
          .collection(AppConstants.playersCollection)
          .doc(uid)
          .snapshots()
          .map((s) => s.exists ? PlayerModel.fromMap(s.data()!, s.id) : null);

  Stream<List<PlayerModel>> streamPlayersByOrg(String organizationId) =>
      _db
          .collection(AppConstants.playersCollection)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('name')
          .snapshots()
          .map((s) => s.docs
              .map((d) => PlayerModel.fromMap(d.data(), d.id))
              .toList());

  Stream<List<PlayerModel>> streamPlayersByBranch(String branchId) =>
      _db
          .collection(AppConstants.playersCollection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('name')
          .snapshots()
          .map((s) => s.docs
              .map((d) => PlayerModel.fromMap(d.data(), d.id))
              .toList());

  // ── Sessions ───────────────────────────────────────────

  Future<String> createSession(Map<String, dynamic> data) async {
    final doc =
        await _db.collection(AppConstants.sessionsCollection).add(data);
    return doc.id;
  }

  Future<void> updateSession(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.sessionsCollection).doc(id).update(data);

  Future<void> deleteSession(String id) =>
      _db.collection(AppConstants.sessionsCollection).doc(id).delete();

  Stream<List<SessionModel>> streamSessionsByBranch(String branchId) =>
      _db
          .collection(AppConstants.sessionsCollection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('dateTime', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => SessionModel.fromMap(d.data(), d.id))
              .toList());

  Stream<List<SessionModel>> streamUpcomingSessionsByBranch(String branchId) =>
      _db
          .collection(AppConstants.sessionsCollection)
          .where('branchId', isEqualTo: branchId)
          .where('dateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 1))))
          .orderBy('dateTime')
          .limit(10)
          .snapshots()
          .map((s) => s.docs
              .map((d) => SessionModel.fromMap(d.data(), d.id))
              .toList());

  // ── Attendance ─────────────────────────────────────────

  Future<void> saveAttendanceBatch(List<AttendanceModel> records) async {
    final batch = _db.batch();
    for (final record in records) {
      final docId = '${record.sessionId}_${record.playerId}';
      batch.set(
        _db.collection(AppConstants.attendanceCollection).doc(docId),
        record.toMap(),
      );
    }
    await batch.commit();
  }

  /// All attendance records for a branch, optionally filtered to [since].
  Stream<List<AttendanceModel>> streamAttendanceByBranch(
    String branchId, {
    DateTime? since,
  }) {
    var query = _db
        .collection(AppConstants.attendanceCollection)
        .where('branchId', isEqualTo: branchId);
    if (since != null) {
      query = query.where('markedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    return query
        .orderBy('markedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AttendanceModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<AttendanceModel>> streamSessionAttendance(String sessionId) =>
      _db
          .collection(AppConstants.attendanceCollection)
          .where('sessionId', isEqualTo: sessionId)
          .snapshots()
          .map((s) => s.docs
              .map((d) => AttendanceModel.fromMap(d.data(), d.id))
              .toList());

  Stream<List<AttendanceModel>> streamPlayerAttendance(String playerId) =>
      _db
          .collection(AppConstants.attendanceCollection)
          .where('playerId', isEqualTo: playerId)
          .orderBy('markedAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => AttendanceModel.fromMap(d.data(), d.id))
              .toList());

  // ── Payments ───────────────────────────────────────────

  Future<String> createPayment(Map<String, dynamic> data) async {
    final doc =
        await _db.collection(AppConstants.paymentsCollection).add(data);
    return doc.id;
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.paymentsCollection).doc(id).update(data);

  Stream<List<PaymentModel>> streamPaymentsByBranch(String branchId) =>
      _db
          .collection(AppConstants.paymentsCollection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => PaymentModel.fromMap(d.data(), d.id))
              .toList());

  Stream<List<PaymentModel>> streamPaymentsByPlayer(String playerId) =>
      _db
          .collection(AppConstants.paymentsCollection)
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => PaymentModel.fromMap(d.data(), d.id))
              .toList());

  // ── Video Analysis ─────────────────────────────────────

  Future<String> createVideoAnalysis(Map<String, dynamic> data) async {
    final doc =
        await _db.collection(AppConstants.videoAnalysisCollection).add(data);
    return doc.id;
  }

  Future<void> updateVideoAnalysis(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.videoAnalysisCollection).doc(id).update(data);

  Future<void> deleteVideoAnalysis(String id) =>
      _db.collection(AppConstants.videoAnalysisCollection).doc(id).delete();

  Stream<List<VideoAnalysisModel>> streamVideoAnalysisByBranch(
          String branchId) =>
      _db
          .collection(AppConstants.videoAnalysisCollection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => VideoAnalysisModel.fromMap(d.data(), d.id))
              .toList());

  // ── Annotations (subcollection of videoAnalysis) ───────

  Future<String> addAnnotation(
      String videoId, Map<String, dynamic> data) async {
    final doc = await _db
        .collection(AppConstants.videoAnalysisCollection)
        .doc(videoId)
        .collection(AppConstants.annotationsCollection)
        .add(data);
    return doc.id;
  }

  Stream<List<VideoAnnotation>> streamAnnotations(String videoId) => _db
      .collection(AppConstants.videoAnalysisCollection)
      .doc(videoId)
      .collection(AppConstants.annotationsCollection)
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs
          .map((d) => VideoAnnotation.fromMap(d.data(), d.id))
          .toList());

  Future<void> deleteAnnotation(String videoId, String annotationId) => _db
      .collection(AppConstants.videoAnalysisCollection)
      .doc(videoId)
      .collection(AppConstants.annotationsCollection)
      .doc(annotationId)
      .delete();

  // ── QR Sessions ────────────────────────────────────────

  Future<String> createQrSession(Map<String, dynamic> data) async {
    final doc =
        await _db.collection(AppConstants.qrSessionsCollection).add(data);
    return doc.id;
  }

  Future<void> deactivateQrSession(String id) =>
      _db.collection(AppConstants.qrSessionsCollection).doc(id).update({
        'isActive': false,
      });

  /// Looks up a QR session by its unique token string.
  Future<QrSessionModel?> getQrSessionByToken(String token) async {
    final snap = await _db
        .collection(AppConstants.qrSessionsCollection)
        .where('token', isEqualTo: token)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return QrSessionModel.fromMap(doc.data(), doc.id);
  }

  /// Live stream so the coach UI can react when the QR is deactivated.
  Stream<QrSessionModel?> streamQrSession(String id) => _db
      .collection(AppConstants.qrSessionsCollection)
      .doc(id)
      .snapshots()
      .map((doc) =>
          doc.exists ? QrSessionModel.fromMap(doc.data()!, doc.id) : null);

  // ── Attendance (single record) ─────────────────────────

  /// Saves or overwrites a single attendance record (used for QR check-in).
  Future<void> saveAttendance(Map<String, dynamic> data) {
    final docId = '${data['sessionId']}_${data['playerId']}';
    return _db
        .collection(AppConstants.attendanceCollection)
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }
}
