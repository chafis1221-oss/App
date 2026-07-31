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
  Timer? _pingTimer;
  final AudioService _audioService = AudioService();
  NotificationService? _notificationService;
  bool _isMonitoring = false;

  final List<String> _logs = [];
  static const int _maxLogs = 500;

  ConnectionStatus get status => _status;
  bool get isMonitoring => _isMonitoring;
  List<String> get logs => List.unmodifiable(_logs);

  void _addLog(String message) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > _maxLogs) _logs.removeLast();
  }

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _addLog('=== START MONITORING ===');
    _isMonitoring = true;
    notifyListeners();
    await _connect();
    _startPing();
  }

  Future<void> stopMonitoring() async {
    _addLog('=== STOP MONITORING ===');
    _isMonitoring = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && _status == ConnectionStatus.connected) {
        try {
          _channel!.sink.add('ping');
        } catch (e) {
          _handleDisconnect();
        }
      }
    });
  }

  Future<void> _connect() async {
    if (!_isMonitoring) return;

    _status = ConnectionStatus.connecting;
    notifyListeners();

    try {
      final wsUrl = await PrefsHelper.getWebSocketUrl();
      final token = await PrefsHelper.getToken();
      final uri = Uri.parse('$wsUrl?token=$token');

      _addLog('Connecting to: $uri');

      _channel = WebSocketChannel.connect(uri);
      _status = ConnectionStatus.connected;
      _addLog('CONNECTED');
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          if (message == 'pong') return;
          _handleMessage(message);
        },
        onError: (error) {
          _addLog('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          _addLog('Connection closed');
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _addLog('Connection failed: $e');
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

        _addLog('Received: $text');

        final history = HistoryModel(id: id, text: text, time: time);
        HistoryManager.addHistory(history);

        _notificationService?.showNotification('QRIS Monitor', text);

        if (audioBase64 != null && audioBase64.isNotEmpty) {
          _audioService.playBase64Audio(audioBase64);
        }
      }
    } catch (e) {
      _addLog('Parse error: $e');
    }
  }

  void _handleDisconnect() {
    _channel = null;
    _status = ConnectionStatus.disconnected;
    _addLog('Disconnected');
    notifyListeners();

    if (_isMonitoring) {
      _reconnectTimer?.cancel();
      _addLog('Reconnecting in 3 seconds...');
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (_isMonitoring) _connect();
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
