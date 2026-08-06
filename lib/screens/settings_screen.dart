import 'package:flutter/material.dart';
import '../utils/prefs_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _urlController.text = PrefsHelper.localUrl;
    _tokenController.text = await PrefsHelper.getToken();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final url = _urlController.text.trim().isEmpty ? PrefsHelper.localUrl : _urlController.text.trim();
    final token = _tokenController.text.trim().isEmpty ? PrefsHelper.defaultToken : _tokenController.text.trim();
    await PrefsHelper.saveWebSocketUrl(url);
    await PrefsHelper.saveToken(token);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengaturan disimpan'),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WebSocket URL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _urlController,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: PrefsHelper.localUrl,
                  hintStyle: TextStyle(color: Colors.grey[350], fontSize: 15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(18),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.url,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Token WebSocket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _tokenController,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: PrefsHelper.defaultToken,
                  hintStyle: TextStyle(color: Colors.grey[350], fontSize: 15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(18),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Default: ${PrefsHelper.localUrl}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isSaving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
