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

  final List<String> _logs = [];
  static const int _maxLogs = 50;

  ConnectionStatus get status => _status;
  bool get isMonitoring => _isMonitoring;
  String get activeUrl => _activeUrl;
  List<String> get logs => List.unmodifiable(_logs);

  void _addLog(String msg) {
    _logs.insert(0, '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $msg');
    if (_logs.length > _maxLogs) _logs.removeLast();
    notifyListeners();
  }

  void setNotificationService(NotificationService s) => _notificationService = s;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _addLog('START');
    notifyListeners();
    await _connect();
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _reconnectTimer?.cancel();
    await _close();
    _status = ConnectionStatus.disconnected;
    _addLog('STOP');
    notifyListeners();
  }

  Future<void> _close() async {
    try { await _channel?.sink.close(); } catch (_) {}
    _channel = null;
  }

  Future<void> _connect() async {
    if (!_isMonitoring) return;
    await _close();

    _status = ConnectionStatus.connecting;
    notifyListeners();
    _addLog('Connecting...');

    final ok = await _tryConnect(PrefsHelper.localUrl);
    if (ok) return;

    _status = ConnectionStatus.disconnected;
    notifyListeners();
    _addLog('Failed');
    _scheduleReconnect();
  }

  Future<bool> _tryConnect(String url) async {
    try {
      final token = await PrefsHelper.getToken();
      _channel = WebSocketChannel.connect(Uri.parse('$url?token=$token'));
      await _channel!.ready;
      _activeUrl = url;
      _status = ConnectionStatus.connected;
      _addLog('CONNECTED');
      notifyListeners();

      _channel!.stream.listen(
        (msg) {
          if (msg == 'pong') return;
          _processMessage(msg);
        },
        onError: (e) {
          _addLog('ERR');
          _cleanup();
        },
        onDone: () {
          _addLog('CLOSED');
          _cleanup();
        },
        cancelOnError: false,
      );
      return true;
    } catch (e) {
      _addLog('FAIL');
      await _close();
      return false;
    }
  }

  void _processMessage(dynamic msg) {
    try {
      final d = jsonDecode(msg);
      if (d['type'] != 'audio') return;
      final text = d['text'] ?? '';
      final time = d['time'] ?? '';
      final id = d['id'] ?? '';
      final audio = d['audio'];

      HistoryManager.addHistory(HistoryModel(id: id, text: text, time: time));
      _addLog('RECV');
      _notificationService?.showNotification('QRIS Monitor', text);
      if (audio != null && audio.isNotEmpty) _audioService.playBase64Audio(audio);
    } catch (_) {}
  }

  void _cleanup() {
    _channel = null;
    if (_isMonitoring) {
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
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
