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

enum ServerMode {
  local,
  domain,
}

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ServerMode _mode = ServerMode.local;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final AudioService _audioService = AudioService();
  NotificationService? _notificationService;
  bool _isMonitoring = false;
  String _activeUrl = '';

  final List<String> _logs = [];
  static const int _maxLogs = 500;

  ConnectionStatus get status => _status;
  ServerMode get mode => _mode;
  bool get isMonitoring => _isMonitoring;
  String get activeUrl => _activeUrl;
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
    await _tryConnect();
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

  Future<void> _tryConnect() async {
    if (!_isMonitoring) return;

    // Coba local dulu
    _mode = ServerMode.local;
    _addLog('Trying LOCAL: ${PrefsHelper.localUrl}');
    final localOk = await _connectTo(PrefsHelper.localUrl);

    if (localOk) {
      _addLog('Connected via LOCAL');
      return;
    }

    // Local gagal, coba domain
    _addLog('Local failed, trying DOMAIN...');
    _mode = ServerMode.domain;
    final domainUrl = await PrefsHelper.getDomainUrl();
    _addLog('Trying DOMAIN: $domainUrl');
    final domainOk = await _connectTo(domainUrl);

    if (domainOk) {
      _addLog('Connected via DOMAIN');
      return;
    }

    // Dua-duanya gagal
    _addLog('Both failed, retrying in 3 seconds...');
    _handleDisconnect();
  }

  Future<bool> _connectTo(String wsUrl) async {
    try {
      _status = ConnectionStatus.connecting;
      notifyListeners();

      final token = await PrefsHelper.getToken();
      final uri = Uri.parse('$wsUrl?token=$token');
      _activeUrl = wsUrl;

      _channel = WebSocketChannel.connect(uri);
      _status = ConnectionStatus.connected;
      _addLog('CONNECTED: $wsUrl');
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          if (message == 'pong') return;
          _handleMessage(message);
        },
        onError: (error) {
          _addLog('Error on $wsUrl: $error');
          _handleDisconnect();
        },
        onDone: () {
          _addLog('Closed: $wsUrl');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      // Tunggu bentar buat verifikasi koneksi
      await Future.delayed(const Duration(seconds: 2));
      if (_status == ConnectionStatus.connected) {
        _startPing();
        return true;
      }
      return false;
    } catch (e) {
      _addLog('Failed: $wsUrl - $e');
      _channel = null;
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      return false;
    }
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
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (_isMonitoring) _tryConnect();
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
