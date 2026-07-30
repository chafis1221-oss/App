import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static const String _wsUrlKey = 'websocket_url';
  static const String _tokenKey = 'websocket_token';

  static Future<String> getWebSocketUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_wsUrlKey) ?? 'ws://192.168.1.100:8080/ws';
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ?? '';
  }

  static Future<void> saveWebSocketUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wsUrlKey, url);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
