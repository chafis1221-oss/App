import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundService {
  static Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'QRIS Monitor Aktif',
      notificationText: 'Monitoring notifikasi QRIS',
      callback: _startCallback,
    );
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }

  static void _startCallback() {
    FlutterForegroundTask.setTaskHandler(MyTaskHandler());
  }
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Service dimulai
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Tidak ada event periodik
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Cleanup
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Tidak ada tombol aksi
  }

  @override
  void onNotificationPressed() {
    // Buka aplikasi saat notifikasi ditekan
  }

  @override
  void onNotificationDismissed() {
    // Tidak ada aksi
  }
}
