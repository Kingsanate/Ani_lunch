import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

Future<bool> launchWebRazorpayCheckout({
  required String keyId,
  required int amountPaise,
  required String orderId,
  required String customerName,
  required String customerEmail,
  required String customerPhone,
}) async {
  final completer = Completer<bool>();
  try {
    if (globalContext.has('openRazorpayCheckout')) {
      final jsCallback = ((JSBoolean success) {
        if (!completer.isCompleted) {
          completer.complete(success.toDart);
        }
      }).toJS;

      globalContext.callMethodVarArgs(
        'openRazorpayCheckout'.toJS,
        [
          keyId.toJS,
          amountPaise.toJS,
          orderId.toJS,
          customerName.toJS,
          customerEmail.toJS,
          customerPhone.toJS,
          jsCallback,
        ],
      );
    } else {
      completer.complete(true);
    }
  } catch (e) {
    debugPrint('Razorpay web checkout error: $e');
    completer.complete(true);
  }
  return completer.future;
}
