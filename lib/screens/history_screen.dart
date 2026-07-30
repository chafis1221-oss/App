import 'package:flutter/material.dart';
import '../models/history_model.dart';
import '../utils/history_manager.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryModel> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final histories = await HistoryManager.getHistory();
    if (mounted) {
      setState(() {
        _histories = histories;
        _isLoading = false;
      });
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Baru saja';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} menit lalu';
      } else if (difference.inDays < 1) {
        return DateFormat('HH:mm').format(dateTime);
      } else {
        return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
      }
    } catch (e) {
      return isoTime;
    }
  }

  IconData _getPaymentIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('dana')) return Icons.account_balance_wallet;
    if (lower.contains('ovo')) return Icons.account_balance_wallet;
    if (lower.contains('gopay')) return Icons.account_balance_wallet;
    if (lower.contains('linkaja')) return Icons.account_balance_wallet;
    if (lower.contains('shopeepay')) return Icons.shopping_bag;
    return Icons.qr_code_2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          if (_histories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus semua',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Hapus Riwayat'),
                    content: const Text(
                      'Semua riwayat notifikasi akan dihapus.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(color: Color(0xFFE74C3C)),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await HistoryManager.clearHistory();
                  _loadHistory();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A1A2E),
              ),
            )
          : _histories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1A1A2E).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inbox_outlined,
                          size: 36,
                          color: Colors.grey[350],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Belum ada notifikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Notifikasi QRIS akan muncul di sini',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: const Color(0xFF1A1A2E),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _histories.length,
                    itemBuilder: (context, index) {
                      final history = _histories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E)
                                    .withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getPaymentIcon(history.text),
                                color: const Color(0xFF1A1A2E),
                                size: 22,
                              ),
                            ),
                            title: Text(
                              history.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _formatTime(history.time),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
