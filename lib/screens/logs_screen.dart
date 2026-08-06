import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WebSocketService>().logs;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Logs', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: logs.isEmpty
          ? const Center(child: Text('Belum ada log', style: TextStyle(color: Colors.grey)))
          : Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('LOGS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${logs.length} entries', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ]),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: logs.length,
                      itemBuilder: (_, i) {
                        Color c = Colors.white70;
                        if (logs[i].contains('ERR') || logs[i].contains('FAIL')) c = const Color(0xFFE74C3C);
                        if (logs[i].contains('CONNECTED') || logs[i].contains('RECV')) c = const Color(0xFF4CAF50);
                        return Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(logs[i], style: TextStyle(color: c, fontSize: 11, fontFamily: 'monospace')));
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
