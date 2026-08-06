import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static const _urlKey = 'websocket_url';
  static const _tokenKey = 'websocket_token';
  static const localUrl = 'ws://192.168.1.17:8080/ws';
  static const defaultToken = 's3cr3tWs';

  static Future<String> getWebSocketUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_urlKey) ?? localUrl;
    } catch (_) {
      return localUrl;
    }
  }

  static Future<String> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey) ?? defaultToken;
    } catch (_) {
      return defaultToken;
    }
  }

  static Future<void> saveWebSocketUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_urlKey, url);
    } catch (_) {}
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }
}
