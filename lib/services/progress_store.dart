import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// めぐりの進み具合（スタンプ・クイズの回答・選んだクーポン）を端末に保存する。
// 2〜3時間歩く途中でアプリが閉じられても、続きから再開できるようにするため。
// Firebase に接続したら、同じ load / save を持つ Firestore 版に差し替える想定
class ProgressStore {
  ProgressStore(this.prefs);

  static const _key = 'meguri_progress_v1';
  // 名前は進み具合と別に保存する（進み具合を最初からにしても名前は残す）
  static const _nameKey = 'meguri_player_name_v1';

  final SharedPreferences prefs;

  String? loadPlayerName() => prefs.getString(_nameKey);

  Future<void> savePlayerName(String name) => prefs.setString(_nameKey, name);

  Map<String, dynamic>? load() {
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      // 壊れたデータで起動できなくなるよりは、最初からやり直せるほうがよい
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> json) => prefs.setString(_key, jsonEncode(json));
}
