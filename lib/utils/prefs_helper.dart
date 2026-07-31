import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static const String _domainUrlKey = 'domain_url';
  static const String _tokenKey = 'websocket_token';

  static const String localUrl = 'ws://192.168.1.17:8080/ws';
  static const String defaultDomainUrl = 'wss://qris.chafis.my.id/ws';
  static const String defaultToken = 's3cr3tWs';

  static Future<String> getDomainUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_domainUrlKey) ?? defaultDomainUrl;
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ?? defaultToken;
  }

  static Future<void> saveDomainUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_domainUrlKey, url);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
