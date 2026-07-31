import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';

class HistoryManager {
  static const _key = 'notification_history';
  static const _max = 50;

  static Future<List<HistoryModel>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.map((e) => HistoryModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addHistory(HistoryModel history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = await getHistory();
      histories.insert(0, history);
      if (histories.length > _max) histories.removeRange(_max, histories.length);
      final json = jsonEncode(histories.map((e) => e.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (_) {}
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
