import 'package:flutter/material.dart';
import '../utils/prefs_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tokenController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _tokenController.text = await PrefsHelper.getToken();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await PrefsHelper.saveToken(_tokenController.text.trim().isEmpty ? PrefsHelper.defaultToken : _tokenController.text.trim());
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Disimpan'), backgroundColor: const Color(0xFF1A1A2E), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Token', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(hintText: PrefsHelper.defaultToken, hintStyle: TextStyle(color: Colors.grey[350]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(18)),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isSaving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
                child: Center(child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
