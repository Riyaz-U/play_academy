import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
import '../core/constants/app_constants.dart';

class PaymentProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  late final PaymentService _paymentService;

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  StreamSubscription<List<PaymentModel>>? _subscription;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  List<PaymentModel> get pendingPayments =>
      _payments.where((p) => p.isPending || p.isOverdue).toList();
  List<PaymentModel> get paidPayments =>
      _payments.where((p) => p.isPaid).toList();

  PaymentProvider() {
    _paymentService = PaymentService();
    _paymentService.onSuccess = _handlePaymentSuccess;
    _paymentService.onError = _handlePaymentError;
  }

  void listenToPlayerPayments(String playerId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamPaymentsByPlayer(playerId).listen((list) {
      _payments = list;
      notifyListeners();
    });
  }

  void listenToBranchPayments(String branchId) {
    _subscription?.cancel();
    _subscription =
        _firestoreService.streamPaymentsByBranch(branchId).listen((list) {
      _payments = list;
      notifyListeners();
    });
  }

  Future<bool> createPaymentInvoice({
    required String playerId,
    required String playerName,
    required String organizationId,
    required String branchId,
    required double amount,
    required String description,
    required DateTime dueDate,
    required String adminUid,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final payment = PaymentModel(
        id: '',
        playerId: playerId,
        playerName: playerName,
        organizationId: organizationId,
        branchId: branchId,
        amount: amount,
        description: description,
        dueDate: dueDate,
        status: AppConstants.paymentPending,
        createdBy: adminUid,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createPayment(payment.toMap());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called from the player payments screen when tapping "Pay Now".
  Future<void> initiatePayment({
    required PaymentModel payment,
    required String playerName,
    required String playerEmail,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _paymentService.initiatePayment(
        paymentDocId: payment.id,
        playerName: playerName,
        playerEmail: playerEmail,
        description: payment.description,
      );
      // _isLoading stays true until success/error callback fires
    } catch (e) {
      _isLoading = false;
      _error = 'Could not initiate payment. Please try again.';
      notifyListeners();
    }
  }

  // Called by Razorpay SDK on success
  String? _currentPaymentDocId;

  void setCurrentPaymentDocId(String id) => _currentPaymentDocId = id;

  void _handlePaymentSuccess(
      String paymentId, String orderId, String signature) async {
    try {
      if (_currentPaymentDocId != null) {
        await _paymentService.verifyPayment(
          paymentDocId: _currentPaymentDocId!,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
        );
      }
      _successMessage = 'Payment successful!';
    } catch (_) {
      _error = 'Payment made but verification failed. Contact support.';
    } finally {
      _isLoading = false;
      _currentPaymentDocId = null;
      notifyListeners();
    }
  }

  void _handlePaymentError(int code, String message) {
    _isLoading = false;
    _error = 'Payment failed: $message';
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _paymentService.dispose();
    super.dispose();
  }
}
