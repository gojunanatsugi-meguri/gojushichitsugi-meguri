// 「次の目的地」と、そこまでの歩数・時間の目安を出す。
// Flutter に依存しないので、テストからそのまま呼べる
import 'package:latlong2/latlong.dart';
import 'meguri_data.dart';

// 1歩の長さ。app_state.dart の stepCount と同じ 0.75m
const stepLengthM = 0.75;
// まっすぐの距離は実際の道のりより短いので、1.3倍して道のりの目安にする
const detourFactor = 1.3;
// 高齢の方の歩く速さの目安（分速60m）
const walkMetersPerMinute = 60.0;

class WalkEstimate {
  final int steps;
  final int minutes;

  const WalkEstimate({required this.steps, required this.minutes});
}

// 地点のデータには座標がないので、その地点の協力店の位置の平均を地点の位置にする
LatLng? checkpointPosition(String checkpointId) {
  final list = shopsAt(checkpointId);
  if (list.isEmpty) return null;
  final lat = list.map((s) => s.lat).reduce((a, b) => a + b) / list.length;
  final lng = list.map((s) => s.lng).reduce((a, b) => a + b) / list.length;
  return LatLng(lat, lng);
}

// 画面に出す地点の名前は、「第1地点」ではなくお店の名前にする（お店が複数なら「・」でつなぐ）。
// お店がない地点は、地点の名前のまま
String spotName(Checkpoint cp) {
  final list = shopsAt(cp.id);
  return list.isEmpty ? cp.name : list.map((s) => s.name).join('・');
}

// お店の種類（かき氷、カフェなど）。重なりは1つにまとめる
String spotCategory(Checkpoint cp) => shopsAt(cp.id).map((s) => s.category).toSet().join('・');

// 次の目的地は、まだスタンプを持っていない地点のうち、順番が一番早いもの。
// すべて集め終わっていたら null
Checkpoint? nextTarget(Set<String> stampedIds) {
  final rest = checkpoints.where((c) => !stampedIds.contains(c.id)).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  return rest.firstOrNull;
}

// 歩数は細かすぎると読みにくいので、1,000歩までは50歩、それより上は100歩単位に丸める
WalkEstimate estimateWalk(LatLng from, LatLng to) {
  final meters = const Distance().as(LengthUnit.Meter, from, to) * detourFactor;
  final raw = meters / stepLengthM;
  final unit = raw < 1000 ? 50 : 100;
  final steps = ((raw / unit).round() * unit).clamp(unit, 1 << 30);
  final minutes = (meters / walkMetersPerMinute).ceil().clamp(1, 1 << 30);
  return WalkEstimate(steps: steps, minutes: minutes);
}
