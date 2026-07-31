import 'package:flutter/material.dart';
import '../utils/prefs_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _localUrlController = TextEditingController();
  final _domainUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isDomain = false;
  bool _isSaving = false;

  static const String _defaultLocalUrl = 'ws://192.168.1.17:8080/ws';
  static const String _defaultDomainUrl = 'wss://qris.chafis.my.id/ws';
  static const String _defaultToken = 's3cr3tWs';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await PrefsHelper.getWebSocketUrl();
    final token = await PrefsHelper.getToken();

    setState(() {
      _isDomain = url.contains('wss://');
      if (_isDomain) {
        _domainUrlController.text = url;
        _localUrlController.text = _defaultLocalUrl;
      } else {
        _localUrlController.text = url;
        _domainUrlController.text = _defaultDomainUrl;
      }
      _tokenController.text = token.isNotEmpty ? token : _defaultToken;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final url = _isDomain
        ? (_domainUrlController.text.trim().isEmpty ? _defaultDomainUrl : _domainUrlController.text.trim())
        : (_localUrlController.text.trim().isEmpty ? _defaultLocalUrl : _localUrlController.text.trim());
    final token = _tokenController.text.trim().isEmpty ? _defaultToken : _tokenController.text.trim();

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
    _localUrlController.dispose();
    _domainUrlController.dispose();
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
            // Mode Switch
            const Text('Mode Koneksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
              child: Row(
                children: [
                  Text(_isDomain ? 'Domain (Cloudflare)' : 'Local (WiFi)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                  const Spacer(),
                  Switch(value: _isDomain, onChanged: (value) => setState(() => _isDomain = value), activeColor: const Color(0xFF1A1A2E)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(_isDomain ? 'WebSocket URL (Domain)' : 'WebSocket URL (Local)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _isDomain ? _domainUrlController : _localUrlController,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(hintText: _isDomain ? _defaultDomainUrl : _defaultLocalUrl, hintStyle: TextStyle(color: Colors.grey[350], fontSize: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(18), filled: true, fillColor: Colors.white),
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
                decoration: InputDecoration(hintText: _defaultToken, hintStyle: TextStyle(color: Colors.grey[350], fontSize: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(18), filled: true, fillColor: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isSaving ? null : _saveSettings,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]),
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
