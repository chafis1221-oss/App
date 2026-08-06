import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';

class DevScreen extends StatefulWidget {
  const DevScreen({super.key});

  @override
  State<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends State<DevScreen> {
  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Dev Console', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 8),
                  _row('Status', service.isMonitoring ? 'Monitoring' : 'Idle'),
                  _row('Connected', service.status == ConnectionStatus.connected ? 'Yes' : 'No'),
                  _row('URL', service.activeUrl.isNotEmpty ? service.activeUrl : '-'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Text('$l: ', style: TextStyle(fontSize: 13, color: Colors.grey[500])), Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))))]));
}
