import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/invitation_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';
import '../core/config/invite_config.dart';

class InvitationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<InvitationModel> _invitations = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  StreamSubscription<List<InvitationModel>>? _subscription;

  List<InvitationModel> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  List<InvitationModel> get pendingInvitations =>
      _invitations.where((i) => i.isPending && !i.isExpired).toList();

  List<InvitationModel> get acceptedInvitations =>
      _invitations.where((i) => i.isAccepted).toList();

  List<InvitationModel> get revokedOrExpiredInvitations => _invitations
      .where((i) => i.isRevoked || (i.isPending && i.isExpired))
      .toList();

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Admin stream ──────────────────────────────────────

  void listenByOrg(String organizationId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamInvitationsByOrg(organizationId).listen((list) {
      _invitations = list;
      notifyListeners();
    });
  }

  // ── Send invite ───────────────────────────────────────

  Future<bool> sendInvite({
    required String email,
    required String role,
    required String organizationId,
    String? branchId,
    String? name,
    required String adminUid,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final invitation = InvitationModel(
        id: '',
        email: email.trim().toLowerCase(),
        role: role,
        organizationId: organizationId,
        branchId: branchId,
        invitedBy: adminUid,
        name: name?.trim().isEmpty == true ? null : name?.trim(),
        invitedAt: now,
        expiresAt: now.add(InviteConfig.inviteExpiry),
        status: AppConstants.inviteStatusPending,
      );

      // Create Firestore doc first — the ID is embedded in the email link URL
      final inviteId =
          await _firestoreService.createInvitation(invitation.toMap());

      // Send the email link with email + inviteId in the continueUrl
      await _authService.sendInviteEmailLink(
        invitation.email,
        InviteConfig.buildActionCodeSettings(invitation.email, inviteId),
      );

      _successMessage = 'Invitation sent to ${invitation.email}';
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Resend ────────────────────────────────────────────

  Future<bool> resendInvite(InvitationModel invite) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _authService.sendInviteEmailLink(
        invite.email,
        InviteConfig.buildActionCodeSettings(invite.email, invite.id),
      );
      _successMessage = 'Invitation resent to ${invite.email}';
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Revoke / delete ───────────────────────────────────

  Future<bool> revokeInvite(String id) async {
    try {
      await _firestoreService.updateInvitationStatus(
          id, AppConstants.inviteStatusRevoked);
      return true;
    } catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInvite(String id) async {
    try {
      await _firestoreService.deleteInvitation(id);
      return true;
    } catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Error mapping ─────────────────────────────────────

  String _mapError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'missing-continue-uri':
        case 'invalid-continue-uri':
          return 'Invite configuration error. Contact support.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        default:
          return e.message ?? 'Failed to send invitation.';
      }
    }
    if (e is FirebaseException) {
      return e.message ?? 'A database error occurred.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
