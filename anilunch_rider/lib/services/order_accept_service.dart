import 'package:flutter/foundation.dart';
import '../core/providers/api_provider.dart';

class OrderAcceptService {
  static Future<bool> acceptOrder(String orderId) async {
    try {
      await AniApi.instance.api.riders.acceptOrder(orderId);
      return true;
    } catch (e) {
      debugPrint('acceptOrder error: $e');
      return false;
    }
  }
}
