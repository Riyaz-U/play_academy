import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = void Function(
    String razorpayPaymentId, String razorpayOrderId, String razorpaySignature);
typedef PaymentErrorCallback = void Function(int code, String message);

class PaymentService {
  late final Razorpay _razorpay;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  PaymentSuccessCallback? onSuccess;
  PaymentErrorCallback? onError;

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  void dispose() => _razorpay.clear();

  /// Step 1 – Ask Cloud Function to create a Razorpay order.
  /// Step 2 – Open the Razorpay checkout sheet.
  Future<void> initiatePayment({
    required String paymentDocId,
    required String playerName,
    required String playerEmail,
    required String description,
  }) async {
    final callable = _functions.httpsCallable('createRazorpayOrder');
    final result = await callable.call({'paymentId': paymentDocId});

    final data = result.data as Map<dynamic, dynamic>;

    final options = {
      'key': data['keyId'] as String,
      'amount': data['amount'] as int, // in paise
      'order_id': data['orderId'] as String,
      'name': 'Play Academy',
      'description': description,
      'prefill': {
        'name': playerName,
        'email': playerEmail,
      },
      'theme': {
        'color': '#1A6B3C',
      },
    };

    _razorpay.open(options);
  }

  /// Step 3 – Verify the payment with the Cloud Function.
  Future<void> verifyPayment({
    required String paymentDocId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final callable = _functions.httpsCallable('verifyRazorpayPayment');
    await callable.call({
      'paymentId': paymentDocId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(
      response.paymentId ?? '',
      response.orderId ?? '',
      response.signature ?? '',
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    onError?.call(response.code ?? 0, response.message ?? 'Payment failed');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // External wallet selected – treat as pending; webhook will update status
  }
}
