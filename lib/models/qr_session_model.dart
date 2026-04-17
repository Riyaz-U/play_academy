import 'package:cloud_firestore/cloud_firestore.dart';

class QrSessionModel {
  final String id;
  final String sessionId;
  final String branchId;
  final String organizationId;
  final String token; // unique UUID encoded into the QR
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  const QrSessionModel({
    required this.id,
    required this.sessionId,
    required this.branchId,
    required this.organizationId,
    required this.token,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
  });

  factory QrSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return QrSessionModel(
      id: id,
      sessionId: map['sessionId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      token: map['token'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'branchId': branchId,
        'organizationId': organizationId,
        'token': token,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isActive': isActive,
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => isActive && !isExpired;
}
