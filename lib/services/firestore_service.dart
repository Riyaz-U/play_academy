import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/organization_model.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';
import '../models/coach_model.dart';
import '../models/player_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/payment_model.dart';
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

  Future<void> deletePlayer(String uid) async {
    await _db.collection(AppConstants.playersCollection).doc(uid).delete();
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }

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

  Stream<List<PaymentModel>> streamPaymentsByPlayer(String playerId) =>
      _db
          .collection(AppConstants.paymentsCollection)
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => PaymentModel.fromMap(d.data(), d.id))
              .toList());

  Stream<List<PaymentModel>> streamPaymentsByBranch(String branchId) =>
      _db
          .collection(AppConstants.paymentsCollection)
          .where('branchId', isEqualTo: branchId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => PaymentModel.fromMap(d.data(), d.id))
              .toList());
}
