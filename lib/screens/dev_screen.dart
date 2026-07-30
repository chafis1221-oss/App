import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../utils/prefs_helper.dart';
import 'dart:convert';

class DevScreen extends StatefulWidget {
  const DevScreen({super.key});

  @override
  State<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends State<DevScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  String _serverUrl = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await PrefsHelper.getWebSocketUrl();
    final token = await PrefsHelper.getToken();
    setState(() {
      _serverUrl = url;
      _token = token;
    });
    _addLog('SETTINGS LOADED');
    _addLog('URL: $url');
    _addLog('Token: ${token.isNotEmpty ? "***${token.substring(token.length - 3)}" : "(empty)"}');
  }

  void _addLog(String message) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 500) {
        _logs.removeLast();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Developer Console',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () {
              setState(() => _logs.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Server info card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WebSocket Info',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow('URL', _serverUrl),
                _infoRow('Token', _token.isNotEmpty ? '${_token.substring(0, 3)}...${_token.substring(_token.length - 3)}' : '(empty)'),
                const SizedBox(height: 8),
                Consumer<WebSocketService>(
                  builder: (context, service, child) {
                    return _infoRow('Status', service.isMonitoring ? 'Monitoring' : 'Idle');
                  },
                ),
              ],
            ),
          ),

          // Test buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _testButton(
                    'Test JSON Parse',
                    Colors.blueGrey,
                    () {
                      _addLog('=== TEST JSON PARSE ===');
                      try {
                        const testJson = '{"id":"test-123","type":"audio","text":"DANA QRIS Rp50000 masuk dari Budi","time":"2026-07-29T17:00:00+07:00","audio":"BASE64_WAV_PLACEHOLDER"}';
                        final parsed = jsonDecode(testJson);
                        _addLog('✅ Parse SUCCESS');
                        _addLog('ID: ${parsed['id']}');
                        _addLog('Type: ${parsed['type']}');
                        _addLog('Text: ${parsed['text']}');
                        _addLog('Time: ${parsed['time']}');
                        _addLog('Audio: ${parsed['audio'] != null ? "PRESENT (${parsed['audio'].toString().length} chars)" : "MISSING"}');
                      } catch (e) {
                        _addLog('❌ Parse FAILED: $e');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _testButton(
                    'Test Audio Decode',
                    Colors.blueGrey,
                    () {
                      _addLog('=== TEST AUDIO DECODE ===');
                      try {
                        final testBase64 = base64Encode([0x52, 0x49, 0x46, 0x46]);
                        final decoded = base64Decode(testBase64);
                        _addLog('✅ Decode SUCCESS');
                        _addLog('Bytes length: ${decoded.length}');
                        _addLog('First 4 bytes: ${decoded.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
                      } catch (e) {
                        _addLog('❌ Decode FAILED: $e');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LOGS',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${_logs.length} entries',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  Expanded(
                    child: _logs.isEmpty
                        ? const Center(
                            child: Text(
                              'No logs yet...',
                              style: TextStyle(color: Colors.white24, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(10),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              Color logColor = Colors.white70;
                              if (log.contains('✅')) logColor = const Color(0xFF4CAF50);
                              if (log.contains('❌')) logColor = const Color(0xFFE74C3C);
                              if (log.contains('===')) logColor = const Color(0xFFFFA726);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    color: logColor,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    height: 1.4,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _testButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
