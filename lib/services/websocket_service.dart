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
enum ServerMode { local, domain }

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ServerMode _mode = ServerMode.local;
  Timer? _reconnectTimer;
  final AudioService _audioService = AudioService();
  NotificationService? _notificationService;
  bool _isMonitoring = false;
  String _activeUrl = '';
  bool _isPlaying = false;

  ConnectionStatus get status => _status;
  ServerMode get mode => _mode;
  bool get isMonitoring => _isMonitoring;
  String get activeUrl => _activeUrl;

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    notifyListeners();
    await _tryConnect();
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  Future<void> _tryConnect() async {
    if (!_isMonitoring) return;
    try { await _channel?.sink.close(); } catch (_) {}
    _channel = null;

    _mode = ServerMode.local;
    bool ok = await _connectTo(PrefsHelper.localUrl);
    if (ok) return;

    _mode = ServerMode.domain;
    final domainUrl = await PrefsHelper.getDomainUrl();
    ok = await _connectTo(domainUrl);
    if (ok) return;

    _scheduleReconnect();
  }

  Future<bool> _connectTo(String wsUrl) async {
    try {
      _status = ConnectionStatus.connecting;
      notifyListeners();
      final token = await PrefsHelper.getToken();
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl?token=$token'));
      _activeUrl = wsUrl;
      _status = ConnectionStatus.connected;
      notifyListeners();

      _channel!.stream.listen(
        (msg) {
          if (msg == 'pong' || _isPlaying) return;
          _handleMessage(msg);
        },
        onError: (_) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
        cancelOnError: false,
      );

      return true;
    } catch (_) {
      _channel = null;
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      return false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] != 'audio') return;

      final text = data['text'] ?? '';
      final time = data['time'] ?? '';
      final id = data['id'] ?? '';
      final audio = data['audio'];

      HistoryManager.addHistory(HistoryModel(id: id, text: text, time: time));
      _notificationService?.showNotification('QRIS Monitor', text);

      if (audio != null && audio.isNotEmpty) {
        _isPlaying = true;
        _audioService.playBase64Audio(audio).then((_) => _isPlaying = false);
      }
    } catch (_) {}
  }

  void _handleDisconnect() {
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_isMonitoring) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _tryConnect);
  }

  @override
  void dispose() {
    stopMonitoring();
    _audioService.dispose();
    super.dispose();
  }
}
