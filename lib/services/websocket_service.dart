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
  Timer? _pingTimer;
  final AudioService _audioService = AudioService();
  NotificationService? _notificationService;
  bool _isMonitoring = false;
  String _activeUrl = '';

  final List<String> _logs = [];
  static const int _maxLogs = 100;

  // Queue untuk audio biar gak numpuk
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;

  ConnectionStatus get status => _status;
  ServerMode get mode => _mode;
  bool get isMonitoring => _isMonitoring;
  String get activeUrl => _activeUrl;
  List<String> get logs => List.unmodifiable(_logs);

  void _addLog(String message) {
    final now = DateTime.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _logs.insert(0, '[$ts] $message');
    if (_logs.length > _maxLogs) _logs.removeLast();
  }

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
    _pingTimer?.cancel();
    _messageQueue.clear();
    _isProcessingQueue = false;
    await _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  Future<void> _tryConnect() async {
    if (!_isMonitoring) return;
    await _channel?.sink.close();
    _channel = null;

    _mode = ServerMode.local;
    final localOk = await _connectTo(PrefsHelper.localUrl);
    if (localOk) return;

    _mode = ServerMode.domain;
    final domainUrl = await PrefsHelper.getDomainUrl();
    final domainOk = await _connectTo(domainUrl);
    if (domainOk) return;

    _handleDisconnect();
  }

  Future<bool> _connectTo(String wsUrl) async {
    try {
      _status = ConnectionStatus.connecting;
      notifyListeners();
      final token = await PrefsHelper.getToken();
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl?token=$token'));
      _activeUrl = wsUrl;
      _status = ConnectionStatus.connected;
      _addLog('CONNECTED: $wsUrl');
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          if (message == 'pong') return;
          _enqueueMessage(message);
        },
        onError: (e) { _handleDisconnect(); },
        onDone: () { _handleDisconnect(); },
        cancelOnError: false,
      );

      await Future.delayed(const Duration(seconds: 1));
      if (_status == ConnectionStatus.connected) {
        _startPing();
        return true;
      }
      return false;
    } catch (e) {
      _channel = null;
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      return false;
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_channel != null && _status == ConnectionStatus.connected) {
        try { _channel!.sink.add('ping'); } catch (e) { _handleDisconnect(); }
      }
    });
  }

  // Queue system: notifikasi tetep tumpuk, audio diproses satu per satu
  void _enqueueMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'audio') {
        _messageQueue.add(data);
        _processQueue();
      }
    } catch (_) {}
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_messageQueue.isNotEmpty) {
      final data = _messageQueue.removeAt(0);
      final text = data['text'] ?? '';
      final time = data['time'] ?? '';
      final id = data['id'] ?? '';
      final audioBase64 = data['audio'];

      // Simpan history + notifikasi tetap tumpuk (gak diantri)
      HistoryManager.addHistory(HistoryModel(id: id, text: text, time: time));
      _notificationService?.showNotification('QRIS Monitor', text);

      // Audio diputar satu per satu
      if (audioBase64 != null && audioBase64.isNotEmpty) {
        await _audioService.playBase64Audio(audioBase64);
        // Tunggu audio selesai sebelum lanjut ke notif berikutnya
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _isProcessingQueue = false;
  }

  void _handleDisconnect() {
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
    if (_isMonitoring) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
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
