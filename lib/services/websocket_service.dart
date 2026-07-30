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

  final List<String> _logs = [];
  static const int _maxLogs = 500;

  ConnectionStatus get status => _status;
  bool get isMonitoring => _isMonitoring;
  List<String> get logs => List.unmodifiable(_logs);

  void _addLog(String message) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }
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
  }

  Future<void> stopMonitoring() async {
    _addLog('=== STOP MONITORING ===');
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

      _addLog('Connecting to: $uri');
      _addLog('URL: $wsUrl');
      _addLog('Token: ${token.isNotEmpty ? "***${token.substring(token.length - 3)}" : "(empty)"}');

      _channel = WebSocketChannel.connect(uri);
      _status = ConnectionStatus.connected;
      _addLog('✅ CONNECTED');
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          _addLog('RAW RECEIVED: ${message.toString().substring(0, message.toString().length > 200 ? 200 : message.toString().length)}...');
          _handleMessage(message);
        },
        onError: (error) {
          _addLog('❌ WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          _addLog('WebSocket connection closed by server');
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _addLog('❌ Connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      _addLog('JSON parsed successfully');

      if (data['type'] == 'audio') {
        final String text = data['text'] ?? '';
        final String time = data['time'] ?? '';
        final String id = data['id'] ?? '';
        final String? audioBase64 = data['audio'];

        _addLog('Type: ${data['type']}');
        _addLog('Text: $text');
        _addLog('Time: $time');
        _addLog('ID: $id');
        _addLog('Audio: ${audioBase64 != null && audioBase64.isNotEmpty ? "PRESENT (${audioBase64.length} chars)" : "MISSING"}');

        final history = HistoryModel(id: id, text: text, time: time);
        HistoryManager.addHistory(history);
        _addLog('✅ History saved');

        _notificationService?.showNotification('QRIS Monitor', text);
        _addLog('✅ Notification shown');

        if (audioBase64 != null && audioBase64.isNotEmpty) {
          _audioService.playBase64Audio(audioBase64);
          _addLog('✅ Audio playback started');
        }
      } else {
        _addLog('⚠️ Unknown message type: ${data['type']}');
        _addLog('Full message: $message');
      }
    } catch (e) {
      _addLog('❌ Parse error: $e');
      _addLog('Raw message: $message');
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
        if (_isMonitoring) {
          _addLog('Attempting reconnect...');
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
