// 歩数（距離）の読み取りのテスト。ヘルスケアの代わりに、決まった値を返す処理を渡して確かめる

import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/models/app_state.dart';

void main() {
  test('読み取った距離が反映される', () async {
    final s = AppState(readDistanceKm: () async => 3.2);
    await s.refreshSteps();
    expect(s.distanceKm, 3.2);
  });

  test('550km より多くても 550km で止まる', () async {
    final s = AppState(readDistanceKm: () async => 600);
    await s.refreshSteps();
    expect(s.distanceKm, 550);
  });

  test('読み取りに失敗しても落ちず、今の距離のまま', () async {
    final s = AppState(readDistanceKm: () async => throw Exception('ヘルスケアが使えない'));
    await s.refreshSteps();
    expect(s.distanceKm, 0);
  });

  test('読み取る処理を渡さなければ、ヘルスケアに問い合わせない', () async {
    final s = AppState();
    await s.refreshSteps();
    expect(s.distanceKm, 0);
  });
}
