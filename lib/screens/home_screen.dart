import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../services/foreground_service.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'dev_screen.dart';
import 'logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tapCount = 0;

  Color _statusColor(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connected: return const Color(0xFF4CAF50);
      case ConnectionStatus.connecting: return const Color(0xFFFFA726);
      case ConnectionStatus.disconnected: return const Color(0xFFBDBDBD);
    }
  }

  String _statusText(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connected: return 'Terhubung';
      case ConnectionStatus.connecting: return 'Menghubungkan...';
      case ConnectionStatus.disconnected: return 'Terputus';
    }
  }

  void _openDev() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DevScreen()));
    }
    Future.delayed(const Duration(seconds: 2), () => _tapCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: GestureDetector(
          onTap: _openDev,
          child: const Text('QRIS Monitor', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.terminal), tooltip: 'Logs', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen()))),
          IconButton(icon: const Icon(Icons.receipt_long_outlined), tooltip: 'Riwayat', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          IconButton(icon: const Icon(Icons.settings_outlined), tooltip: 'Pengaturan', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Consumer<WebSocketService>(
        builder: (context, service, child) {
          final displayUrl = service.activeUrl.isNotEmpty ? service.activeUrl : 'Menunggu...';
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))]),
                    child: Column(
                      children: [
                        Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF1A1A2E).withOpacity(0.05), shape: BoxShape.circle), child: const Icon(Icons.qr_code_2_rounded, size: 36, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 16),
                        const Text('QRIS Monitor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        Text('Pantau notifikasi QRIS real-time', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(service.status))),
                              const SizedBox(width: 10),
                              Text(_statusText(service.status), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(displayUrl, style: TextStyle(fontSize: 12, color: Colors.grey[400]), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      try {
                        if (!service.isMonitoring) {
                          await service.startMonitoring();
                          await ForegroundService.startService();
                        } else {
                          await service.stopMonitoring();
                          await ForegroundService.stopService();
                        }
                      } catch (_) {}
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: service.isMonitoring ? const Color(0xFFE74C3C) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: (service.isMonitoring ? const Color(0xFFE74C3C) : const Color(0xFF1A1A2E)).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(service.isMonitoring ? Icons.stop_circle_outlined : Icons.play_circle_outline, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(service.isMonitoring ? 'Hentikan Monitoring' : 'Mulai Monitoring', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(service.isMonitoring ? 'Aplikasi berjalan di background' : 'Tekan untuk memulai', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
