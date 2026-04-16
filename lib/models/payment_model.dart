import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class PaymentModel {
  final String id;
  final String playerId;
  final String playerName;
  final String organizationId;
  final String branchId;
  final double amount; // in INR
  final String description; // e.g., "Monthly fee - April 2026"
  final DateTime dueDate;
  final String status; // 'pending' | 'paid' | 'overdue'
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime? paidAt;
  final String createdBy; // admin uid
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.organizationId,
    required this.branchId,
    required this.amount,
    required this.description,
    required this.dueDate,
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.paidAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isPending => status == AppConstants.paymentPending;
  bool get isPaid => status == AppConstants.paymentPaid;
  bool get isOverdue => status == AppConstants.paymentOverdue;

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? AppConstants.paymentPending,
      razorpayOrderId: map['razorpayOrderId'] as String?,
      razorpayPaymentId: map['razorpayPaymentId'] as String?,
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'organizationId': organizationId,
      'branchId': branchId,
      'amount': amount,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
      if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
