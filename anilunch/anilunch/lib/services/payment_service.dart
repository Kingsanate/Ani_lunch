import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/api_provider.dart';

class PaymentService {
  static Future<String> processOnlinePayment({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      // Server-authoritative payment intent via the Go API.
      final intent = await AniApi.instance.api.payments.createIntent(orderId);
      final paymentUrl = intent.paymentLink;
      if (paymentUrl.isNotEmpty) {
        final uri = Uri.parse(paymentUrl);
        final launchMode =
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: launchMode);
          return 'launched';
        }
      }
      return 'launched';
    } on TimeoutException {
      return 'Request timed out. Please check your internet connection.';
    } catch (e) {
      debugPrint('Payment notice: $e');
      return 'launched';
    }
  }

  // waitForPaymentCompletion resolves as soon as the order is paid/failed,
  // racing a realtime order:{id} event against a lightweight poll.
  static Future<String> waitForPaymentCompletion(String orderId) async {
    final realtime = AniApi.instance.realtime;
    final completer = Completer<String>();
    StreamSubscription<WsEvent>? sub;

    if (realtime.isConnected) {
      realtime.join('order:$orderId');
      sub = realtime.events.listen((event) {
        final orderEvent = event.orderEvent;
        if (orderEvent == null || orderEvent.orderId != orderId) return;
        final status = orderEvent.status.toLowerCase();
        if (status == 'paid' || status == 'confirmed') {
          completer.complete('success');
        } else if (status == 'failed') {
          completer.complete('failed');
        }
      });
    }

    try {
      return await Future.any<String>([
        completer.future,
        _pollOrderStatus(orderId),
      ]);
    } finally {
      await sub?.cancel();
      realtime.leave('order:$orderId');
    }
  }

  static Future<String> _pollOrderStatus(String orderId) async {
    int attempts = 0;
    const maxAttempts = 60;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final order = await AniApi.instance.api.orders.get(orderId);
        final status = order.status.toLowerCase();
        final paymentStatus = order.paymentStatus.toLowerCase();
        if (status == 'paid' ||
            status == 'confirmed' ||
            paymentStatus == 'paid') {
          return 'success';
        }
        if (status == 'failed' || paymentStatus == 'failed') {
          return 'failed';
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
      attempts++;
    }
    return 'timeout';
  }
}