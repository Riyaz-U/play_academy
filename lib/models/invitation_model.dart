import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class InvitationModel {
  final String id;
  final String email;
  final String role;           // roleCoach | rolePlayer | roleGuardian
  final String organizationId;
  final String? branchId;      // null for guardians (org-level accounts)
  final String invitedBy;      // admin uid
  final String? name;          // optional — pre-fills the accept screen
  final DateTime invitedAt;
  final DateTime expiresAt;
  final String status;         // pending | accepted | revoked

  const InvitationModel({
    required this.id,
    required this.email,
    required this.role,
    required this.organizationId,
    this.branchId,
    required this.invitedBy,
    this.name,
    required this.invitedAt,
    required this.expiresAt,
    required this.status,
  });

  bool get isPending => status == AppConstants.inviteStatusPending;
  bool get isAccepted => status == AppConstants.inviteStatusAccepted;
  bool get isRevoked => status == AppConstants.inviteStatusRevoked;
  bool get isExpired =>
      isPending && DateTime.now().isAfter(expiresAt);

  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id: id,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String?,
      invitedBy: map['invitedBy'] as String? ?? '',
      name: map['name'] as String?,
      invitedAt: map['invitedAt'] != null
          ? (map['invitedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
      status: map['status'] as String? ?? AppConstants.inviteStatusPending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'organizationId': organizationId,
      if (branchId != null) 'branchId': branchId,
      'invitedBy': invitedBy,
      if (name != null) 'name': name,
      'invitedAt': Timestamp.fromDate(invitedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }

  InvitationModel copyWith({String? status}) {
    return InvitationModel(
      id: id,
      email: email,
      role: role,
      organizationId: organizationId,
      branchId: branchId,
      invitedBy: invitedBy,
      name: name,
      invitedAt: invitedAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
    );
  }
}
