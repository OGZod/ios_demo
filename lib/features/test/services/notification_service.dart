import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('app/notification_status');

  static Future<void> enableDoNotDisturb() async {
    try {
      await _channel.invokeMethod('setNotificationStatus', {'enabled': true});
    } catch (e) {
      if (kDebugMode) {
        print('Failed to enable DND mode: $e');
      }
    }
  }

  static Future<void> disableDoNotDisturb() async {
    try {
      await _channel.invokeMethod('setNotificationStatus', {'enabled': false});
    } catch (e) {
      if (kDebugMode) {
        print('Failed to disable DND mode: $e');
      }
    }
  }
}
