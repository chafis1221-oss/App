import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static const _domainKey = 'domain_url';
  static const _tokenKey = 'websocket_token';

  static const localUrl = 'ws://192.168.1.17:8080/ws';
  static const defaultDomainUrl = 'wss://qris.chafis.my.id/ws';
  static const defaultToken = 's3cr3tWs';

  static Future<String> getDomainUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_domainKey) ?? defaultDomainUrl;
    } catch (_) {
      return defaultDomainUrl;
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

  static Future<void> saveDomainUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_domainKey, url);
    } catch (_) {}
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }
}
