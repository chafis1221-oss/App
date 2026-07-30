import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/history_model.dart';
import '../utils/prefs_helper.dart';
import '../utils/history_manager.dart';
import 'audio_service.dart';
import 'notification_service.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _reconnectTimer;
  final AudioService _audioService = AudioService();
  NotificationService? _notificationService;
  bool _isMonitoring = false;

  ConnectionStatus get status => _status;
  bool get isMonitoring => _isMonitoring;

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    notifyListeners();
    await _connect();
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  Future<void> _connect() async {
    if (!_isMonitoring) return;

    _status = ConnectionStatus.connecting;
    notifyListeners();

    try {
      final wsUrl = await PrefsHelper.getWebSocketUrl();
      final token = await PrefsHelper.getToken();
      final uri = Uri.parse('$wsUrl?token=$token');

      _channel = WebSocketChannel.connect(uri);
      _status = ConnectionStatus.connected;
      notifyListeners();

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);

      if (data['type'] == 'audio') {
        final String text = data['text'] ?? '';
        final String time = data['time'] ?? '';
        final String id = data['id'] ?? '';
        final String? audioBase64 = data['audio'];

        final history = HistoryModel(id: id, text: text, time: time);
        HistoryManager.addHistory(history);

        _notificationService?.showNotification('QRIS Monitor', text);

        if (audioBase64 != null && audioBase64.isNotEmpty) {
          _audioService.playBase64Audio(audioBase64);
        }
      }
    } catch (e) {
      // Ignore malformed messages
    }
  }

  void _handleDisconnect() {
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();

    if (_isMonitoring) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (_isMonitoring) {
          _connect();
        }
      });
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    _audioService.dispose();
    super.dispose();
  }
}
