import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onTap,
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  void _onTap(NotificationResponse response) {}

  Future<void> showNotification(String title, String body) async {
    if (!_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'qris_monitor_channel',
        'QRIS Notifications',
        channelDescription: 'QRIS payment notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      // Permission denied, skip silently
    }
  }
}
