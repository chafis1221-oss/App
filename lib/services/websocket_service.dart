import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/history_model.dart';
import '../utils/prefs_helper.dart';
import '../utils/history_manager.dart';
import 'audio_service.dart';
import 'notification_service.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _reconnectTimer;
  final AudioService _audioService = AudioService();
  NotificationService? _notificationService;
  bool _isMonitoring = false;
  String _activeUrl = '';
  bool _useLocal = true;

  // Log ringan untuk tampilan App Log
  final List<String> _logs = [];
  static const int _maxLogs = 50;

  ConnectionStatus get status => _status;
  bool get isMonitoring => _isMonitoring;
  String get activeUrl => _activeUrl;
  bool get isLocal => _useLocal;
  List<String> get logs => List.unmodifiable(_logs);

  void _addLog(String message) {
    final now = DateTime.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _logs.insert(0, '[$ts] $message');
    if (_logs.length > _maxLogs) _logs.removeLast();
    notifyListeners();
  }

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _addLog('Start Monitoring');
    notifyListeners();
    _connect();
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _reconnectTimer?.cancel();
    await _closeChannel();
    _status = ConnectionStatus.disconnected;
    _addLog('Stop Monitoring');
    notifyListeners();
  }

  Future<void> _closeChannel() async {
    try { await _channel?.sink.close(); } catch (_) {}
    _channel = null;
  }

  void _connect() {
    if (!_isMonitoring) return;
    _closeChannel();
    _status = ConnectionStatus.connecting;
    notifyListeners();

    _tryConnect(PrefsHelper.localUrl).then((success) {
      if (success) return;
      _useLocal = false;
      PrefsHelper.getDomainUrl().then((domainUrl) {
        _tryConnect(domainUrl).then((domainSuccess) {
          if (!domainSuccess) {
            _useLocal = true;
            _status = ConnectionStatus.disconnected;
            notifyListeners();
            _scheduleReconnect();
          }
        });
      });
    });
  }

  Future<bool> _tryConnect(String wsUrl) async {
    try {
      final token = await PrefsHelper.getToken();
      final uri = Uri.parse('$wsUrl?token=$token');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _activeUrl = wsUrl;
      _status = ConnectionStatus.connected;
      _addLog('Connected: $wsUrl');
      notifyListeners();

      _channel!.stream.listen(
        (msg) {
          if (msg == 'pong') return;
          _processMessage(msg);
        },
        onError: (e) {
          _addLog('Error: $e');
          _cleanup();
        },
        onDone: () {
          _addLog('Disconnected');
          _cleanup();
        },
        cancelOnError: false,
      );

      return true;
    } catch (e) {
      _addLog('Failed: $wsUrl');
      await _closeChannel();
      return false;
    }
  }

  void _cleanup() {
    _channel = null;
    if (_isMonitoring) {
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _processMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] != 'audio') return;

      final text = data['text'] ?? '';
      final time = data['time'] ?? '';
      final id = data['id'] ?? '';
      final audio = data['audio'];

      HistoryManager.addHistory(HistoryModel(id: id, text: text, time: time));

      try {
        _notificationService?.showNotification('QRIS Monitor', text);
      } catch (_) {}

      if (audio != null && audio.isNotEmpty) {
        _audioService.playBase64Audio(audio);
      }
      _addLog('Received: $text');
    } catch (_) {}
  }

  void _scheduleReconnect() {
    if (!_isMonitoring) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
  }

  @override
  void dispose() {
    stopMonitoring();
    _audioService.dispose();
    super.dispose();
  }
}
