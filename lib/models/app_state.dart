import 'package:flutter/material.dart';
import '../services/progress_store.dart';
import 'meguri_data.dart';

// 画面側は今までどおり app_state.dart だけ import すればデータも使えるようにする
export 'meguri_data.dart';

class Rank {
  final String key;
  final String label;
  final Color color;
  final double minKm;

  const Rank({
    required this.key,
    required this.label,
    required this.color,
    required this.minKm,
  });
}

// 位（ランク）の段階。歩いた距離(km)の累計で判定する
const List<Rank> ranks = [
  Rank(key: 'tabibito', label: '旅人', color: Color(0xFFB08D57), minKm: 0),
  Rank(key: 'hikyaku', label: '飛脚', color: Color(0xFF8C8C8C), minKm: 110),
  Rank(key: 'tonya', label: '問屋', color: Color(0xFFC9A227), minKm: 220),
  Rank(key: 'honjin', label: '本陣', color: Color(0xFFC9A227), minKm: 330),
  Rank(key: 'daimyo', label: '大名', color: Color(0xFFD4AF37), minKm: 440),
];

enum CheckInResult { newStamp, alreadyStamped }

class AppState extends ChangeNotifier {
  // 下タブの現在位置（0:スタンプ帳 1:QR読取 2:クイズ 3:クーポン 4:地図）
  int currentTabIndex = 0;

  void goToTab(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  // デモ用の暫定値。実際は Health 連携プラグインから取得した歩数を距離に換算する
  double distanceKm = 42;
  // 地点ID → スタンプを獲得した日時。日時は、あとでサーバー側で
  // 「移動時間が短すぎないか」などを確かめるときに使えるよう残している
  final Map<String, DateTime> stampedAt = {};
  String? lastScannedCheckpointId;
  // 地点ID → 正解したか。クイズは1地点1回だけ（QRを読み直してもやり直せない）
  final Map<String, bool> quizResults = {};
  // 地点ID（正解したクイズ）→ 選んだ店ID。1問につきクーポンは1店だけ
  final Map<String, String> couponChoices = {};

  // 進み具合の保存先。null のとき（テストなど）は保存しない
  final ProgressStore? store;

  AppState({this.store}) {
    final saved = store?.load();
    if (saved != null) _restore(saved);
  }

  Set<String> get stampedCheckpointIds => stampedAt.keys.toSet();

  bool get allStamped => checkpoints.every((c) => stampedAt.containsKey(c.id));

  List<Checkpoint> get unstampedCheckpoints => checkpoints.where((c) => !stampedAt.containsKey(c.id)).toList();

  List<Shop> get obtainedCoupons => couponChoices.values.map(findShopById).whereType<Shop>().toList();

  Rank get currentRank {
    Rank current = ranks.first;
    for (final r in ranks) {
      if (distanceKm >= r.minKm) current = r;
    }
    return current;
  }

  double get rankProgress => (distanceKm / 550 * 100).clamp(0, 100);

  void addDemoDistance(double km) {
    distanceKm = ((distanceKm + km) * 10).round() / 10;
    if (distanceKm > 550) distanceKm = 550;
    notifyListeners();
  }

  // QRを読んで（必要なら位置確認も済ませて）到着が確定したときに呼ぶ
  CheckInResult checkIn(Shop shop, {DateTime? now}) {
    final isNew = !stampedAt.containsKey(shop.checkpointId);
    if (isNew) stampedAt[shop.checkpointId] = now ?? DateTime.now();
    lastScannedCheckpointId = shop.checkpointId;
    _changed();
    return isNew ? CheckInResult.newStamp : CheckInResult.alreadyStamped;
  }

  // すでに答えた地点の回答は上書きしない
  void answerQuiz(String checkpointId, String choice) {
    final quiz = findCheckpointById(checkpointId)?.quiz;
    if (quiz == null || quizResults.containsKey(checkpointId)) return;
    if (!stampedAt.containsKey(checkpointId)) return;
    quizResults[checkpointId] = choice == quiz.correctAnswer;
    _changed();
  }

  // クーポン候補は「次の地点」の協力店のうち、まだクーポンを持っていない店
  List<Shop> couponCandidates(String checkpointId) {
    final cp = findCheckpointById(checkpointId);
    final next = cp == null ? null : nextCheckpointOf(cp);
    if (next == null) return [];
    final owned = couponChoices.values.toSet();
    return shopsAt(next.id).where((s) => !owned.contains(s.id)).toList();
  }

  bool canChooseCoupon(String checkpointId) =>
      quizResults[checkpointId] == true && !couponChoices.containsKey(checkpointId);

  void chooseCoupon(String checkpointId, String shopId) {
    if (!canChooseCoupon(checkpointId)) return;
    if (!couponCandidates(checkpointId).any((s) => s.id == shopId)) return;
    couponChoices[checkpointId] = shopId;
    _changed();
  }

  // 開発用：めぐりの進み具合を最初からにする
  void resetProgress() {
    stampedAt.clear();
    quizResults.clear();
    couponChoices.clear();
    lastScannedCheckpointId = null;
    _changed();
  }

  void _changed() {
    store?.save(toJson());
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'stampedAt': stampedAt.map((k, v) => MapEntry(k, v.toIso8601String())),
        'lastScannedCheckpointId': lastScannedCheckpointId,
        'quizResults': quizResults,
        'couponChoices': couponChoices,
      };

  // 地点やクイズのデータが変わって、保存済みのIDが存在しなくなっていても落ちないよう、
  // 今のデータにあるIDだけを読み込む
  void _restore(Map<String, dynamic> json) {
    bool knownCp(String id) => findCheckpointById(id) != null;

    final stamped = json['stampedAt'];
    if (stamped is Map) {
      for (final e in stamped.entries) {
        final at = DateTime.tryParse('${e.value}');
        if (knownCp('${e.key}') && at != null) stampedAt['${e.key}'] = at;
      }
    }
    final last = json['lastScannedCheckpointId'];
    if (last is String && stampedAt.containsKey(last)) lastScannedCheckpointId = last;

    final results = json['quizResults'];
    if (results is Map) {
      for (final e in results.entries) {
        if (stampedAt.containsKey('${e.key}') && e.value is bool) quizResults['${e.key}'] = e.value as bool;
      }
    }
    final choices = json['couponChoices'];
    if (choices is Map) {
      for (final e in choices.entries) {
        if (quizResults['${e.key}'] == true && findShopById('${e.value}') != null) {
          couponChoices['${e.key}'] = '${e.value}';
        }
      }
    }
  }
}
