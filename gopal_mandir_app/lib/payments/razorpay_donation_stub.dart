/// Outcome of Razorpay Checkout (payment success with fields needed for server verify).
class RazorpayPaymentOutcome {
  final String orderId;
  final String paymentId;
  final String signature;

  RazorpayPaymentOutcome({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });
}

bool get isRazorpayCheckoutSupported => false;

/// Web: Razorpay mobile SDK is not available.
Future<RazorpayPaymentOutcome?> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String name,
  required String contact,
  required String email,
  required String description,
}) async =>
    null;
