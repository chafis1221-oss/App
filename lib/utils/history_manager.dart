import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';

class HistoryManager {
  static const String _historyKey = 'notification_history';
  static const int _maxHistory = 100;

  static Future<List<HistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_historyKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => HistoryModel.fromJson(json)).toList();
  }

  static Future<void> addHistory(HistoryModel history) async {
    final prefs = await SharedPreferences.getInstance();
    final List<HistoryModel> histories = await getHistory();

    histories.insert(0, history);

    if (histories.length > _maxHistory) {
      histories.removeRange(_maxHistory, histories.length);
    }

    final String jsonString = jsonEncode(
      histories.map((h) => h.toJson()).toList(),
    );

    await prefs.setString(_historyKey, jsonString);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
