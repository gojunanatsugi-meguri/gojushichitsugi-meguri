// 「次の目的地」と、そこまでの歩数・時間の目安のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:gojushichitsugi_meguri/models/meguri_data.dart';
import 'package:gojushichitsugi_meguri/models/route_guide.dart';

void main() {
  test('次の目的地は、まだスタンプを持っていない地点のうち順番が一番早いもの', () {
    expect(nextTarget({})?.id, 'cp1');
    expect(nextTarget({'cp1', 'cp2'})?.id, 'cp3');
    // 飛ばした地点があれば、そこに戻る
    expect(nextTarget({'cp1', 'cp3'})?.id, 'cp2');
    expect(nextTarget(checkpoints.map((c) => c.id).toSet()), isNull);
  });

  test('画面に出す地点の名前は、お店の名前になる', () {
    final cp1 = findCheckpointById('cp1')!;
    expect(spotName(cp1), '枚方凍氷');
    expect(spotCategory(cp1), 'かき氷');
  });

  test('地点の位置は、その地点の協力店の位置になる', () {
    final shop = shopsAt('cp1').single;
    expect(checkpointPosition('cp1'), LatLng(shop.lat, shop.lng));
    expect(checkpointPosition('unknown'), isNull);
  });

  test('歩数は道のり（まっすぐの1.3倍）を0.75mで割り、キリのいい数に丸める', () {
    const from = LatLng(34.8100, 135.6400);
    // 北へ約300m → 道のり約390m → 約520歩 → 500歩、分速60mで7分
    const to = LatLng(34.8127, 135.6400);
    final e = estimateWalk(from, to);
    expect(e.steps, 500);
    expect(e.minutes, 7);
  });

  test('1,000歩を超えると100歩単位、近すぎても最低50歩・1分', () {
    const from = LatLng(34.8100, 135.6400);
    expect(estimateWalk(from, const LatLng(34.8200, 135.6400)).steps % 100, 0);
    final same = estimateWalk(from, from);
    expect(same.steps, 50);
    expect(same.minutes, 1);
  });

  test('50歩以内か1分以内なら「地点周辺」、それより遠ければ歩数を出す', () {
    const from = LatLng(34.8100, 135.6400);
    expect(estimateWalk(from, from).isNearby, isTrue);
    // 北へ約40m → 道のり約52m → 1分
    expect(estimateWalk(from, const LatLng(34.81036, 135.6400)).isNearby, isTrue);
    // 北へ約300m → 500歩・7分
    expect(estimateWalk(from, const LatLng(34.8127, 135.6400)).isNearby, isFalse);
  });
}
