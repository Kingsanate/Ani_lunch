import 'dart:async';

Future<bool> launchWebRazorpayCheckout({
  required String keyId,
  required int amountPaise,
  required String orderId,
  required String customerName,
  required String customerEmail,
  required String customerPhone,
}) async {
  // Safe no-op on non-web platforms (mobile, desktop, VM tests)
  return true;
}
