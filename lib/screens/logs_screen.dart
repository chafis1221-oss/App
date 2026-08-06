import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../utils/prefs_helper.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _serverLogs = [];
  bool _loadingServer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchServerLogs();
  }

  Future<void> _fetchServerLogs() async {
    setState(() => _loadingServer = true);
    try {
      final domainUrl = await PrefsHelper.getDomainUrl();
      String baseUrl = 'http://192.168.1.17:8080';
      try {
        final response = await http.get(Uri.parse('$baseUrl/logs/access')).timeout(const Duration(seconds: 3));
        if (response.statusCode != 200) throw Exception();
      } catch (_) {
        baseUrl = domainUrl.replaceAll('/ws', '').replaceAll('ws://', 'http://').replaceAll('wss://', 'https://');
      }

      final response = await http.get(Uri.parse('$baseUrl/logs/access')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _serverLogs = data.map((e) => e.toString()).toList());
      }
    } catch (_) {
      setState(() => _serverLogs = ['Gagal mengambil log server']);
    }
    setState(() => _loadingServer = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Logs', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A1A2E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1A1A2E),
          tabs: const [
            Tab(text: 'Server Log'),
            Tab(text: 'App Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loadingServer
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
              : _buildLogList(_serverLogs, () => _fetchServerLogs()),
          Consumer<WebSocketService>(
            builder: (context, service, child) {
              final appLogs = service.logs;
              return appLogs.isEmpty
                  ? const Center(child: Text('Belum ada log aplikasi', style: TextStyle(color: Colors.grey)))
                  : _buildLogList(appLogs, null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<String> logs, VoidCallback? onRefresh) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LOGS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text('${logs.length} entries', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    if (onRefresh != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onRefresh,
                        child: const Icon(Icons.refresh, color: Colors.white38, size: 16),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                Color color = Colors.white70;
                if (log.contains('Error') || log.contains('error')) color = const Color(0xFFE74C3C);
                if (log.contains('broadcast') || log.contains('sent') || log.contains('Connected')) color = const Color(0xFF4CAF50);
                if (log.contains('SKIPPED')) color = const Color(0xFFFFA726);
                if (log.contains('Received')) color = const Color(0xFF64B5F6);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace', height: 1.4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
