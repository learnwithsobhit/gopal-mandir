import 'dart:async';
import 'dart:io' show Platform;

import 'package:razorpay_flutter/razorpay_flutter.dart';

bool get isRazorpayCheckoutSupported => Platform.isAndroid || Platform.isIOS;

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

/// Opens Razorpay Checkout on Android / iOS. Returns null if unsupported or user cancelled.
Future<RazorpayPaymentOutcome?> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String name,
  required String contact,
  required String email,
  required String description,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return null;
  }

  final completer = Completer<RazorpayPaymentOutcome?>();
  final razorpay = Razorpay();

  void finish(RazorpayPaymentOutcome? v) {
    try {
      razorpay.clear();
    } catch (_) {}
    if (!completer.isCompleted) {
      completer.complete(v);
    }
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    final oid = response.orderId ?? '';
    final pid = response.paymentId ?? '';
    final sig = response.signature ?? '';
    if (oid.isEmpty || pid.isEmpty || sig.isEmpty) {
      finish(null);
      return;
    }
    finish(RazorpayPaymentOutcome(orderId: oid, paymentId: pid, signature: sig));
  });

  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    final code = response.code?.toString() ?? '';
    final msg = (response.message ?? '').toLowerCase();
    final cancelled = (code.contains('USER') && code.contains('CANCEL')) ||
        msg.contains('cancel');
    try {
      razorpay.clear();
    } catch (_) {}
    if (!completer.isCompleted) {
      if (cancelled) {
        completer.complete(null);
      } else {
        completer.completeError(response.message ?? 'Payment failed');
      }
    }
  });

  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

  razorpay.open({
    'key': keyId,
    'amount': amountPaise,
    'currency': 'INR',
    'name': 'Shri Gopal Mandir',
    'description': description.isEmpty ? 'Donation' : description,
    'order_id': orderId,
    'prefill': {
      'contact': contact,
      'email': email,
      'name': name,
    },
    'theme': {'color': '#3949AB'},
  });

  return completer.future;
}
