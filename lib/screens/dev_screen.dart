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
  final ScrollController _scrollController = ScrollController();
  String _domainUrl = '';
  String _token = '';
  final List<String> _localLogs = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await PrefsHelper.getDomainUrl();
    final token = await PrefsHelper.getToken();
    setState(() {
      _domainUrl = url;
      _token = token;
    });
    _addLocalLog('SETTINGS | Domain: $url | Token: ${token.isNotEmpty ? "***${token.substring(token.length - 3)}" : "(empty)"}');
  }

  void _addLocalLog(String message) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _localLogs.insert(0, '[$timestamp] $message');
      if (_localLogs.length > 500) _localLogs.removeLast();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsLogs = context.watch<WebSocketService>().logs;
    final allLogs = [..._localLogs, ...wsLogs];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Developer Console', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Clear logs', onPressed: () => setState(() => _localLogs.clear())),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WebSocket Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                _infoRow('Local', PrefsHelper.localUrl),
                _infoRow('Domain', _domainUrl),
                _infoRow('Token', _token.isNotEmpty ? '${_token.substring(0, 3)}...${_token.substring(_token.length - 3)}' : '(empty)'),
                const SizedBox(height: 8),
                Consumer<WebSocketService>(builder: (context, service, child) {
                  return _infoRow('Status', '${service.isMonitoring ? "Monitoring" : "Idle"} | ${service.mode == ServerMode.local ? "Local" : "Domain"} | ${service.activeUrl}');
                }),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('LOGS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${allLogs.length} entries', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  Expanded(
                    child: allLogs.isEmpty
                        ? const Center(child: Text('No logs yet...', style: TextStyle(color: Colors.white24, fontSize: 14)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(10),
                            itemCount: allLogs.length,
                            itemBuilder: (context, index) {
                              final log = allLogs[index];
                              Color logColor = Colors.white70;
                              if (log.contains('CONNECTED')) logColor = const Color(0xFF4CAF50);
                              if (log.contains('Failed')) logColor = const Color(0xFFE74C3C);
                              if (log.contains('===')) logColor = const Color(0xFFFFA726);
                              if (log.contains('Trying')) logColor = const Color(0xFF64B5F6);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(log, style: TextStyle(color: logColor, fontSize: 12, fontFamily: 'monospace', height: 1.4)),
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
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
