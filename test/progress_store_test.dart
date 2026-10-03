// 進み具合の保存と、アプリを開き直したときの復元のテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gojushichitsugi_meguri/models/app_state.dart';
import 'package:gojushichitsugi_meguri/services/progress_store.dart';

Future<ProgressStore> storeWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return ProgressStore(await SharedPreferences.getInstance());
}

void main() {
  test('アプリを開き直しても、スタンプ・回答・クーポンが残っている', () async {
    final store = await storeWith({});
    final before = AppState(store: store);
    final at = DateTime(2027, 1, 27, 10, 30);
    before.checkIn(findShopById('shop1')!, now: at);
    before.answerQuiz('cp1', 'KAORU');
    before.chooseCoupon('cp1', 'shop2');

    final after = AppState(store: store);
    expect(after.stampedAt, {'cp1': at});
    expect(after.lastScannedCheckpointId, 'cp1');
    expect(after.quizResults, {'cp1': true});
    expect(after.obtainedCoupons.map((s) => s.id), ['shop2']);
  });

  test('今のデータにない地点や店のIDは読み込まない', () async {
    final store = await storeWith({});
    await store.save({
      'stampedAt': {'cp1': '2027-01-27T10:00:00.000', 'cp99': '2027-01-27T10:00:00.000'},
      'lastScannedCheckpointId': 'cp99',
      'quizResults': {'cp1': true, 'cp99': true},
      'couponChoices': {'cp1': 'shop99'},
    });
    final s = AppState(store: store);
    expect(s.stampedCheckpointIds, {'cp1'});
    expect(s.lastScannedCheckpointId, isNull);
    expect(s.quizResults, {'cp1': true});
    expect(s.couponChoices, isEmpty);
  });

  test('保存データが壊れていても、最初から始められる', () async {
    final store = await storeWith({'meguri_progress_v1': '{壊れたデータ'});
    final s = AppState(store: store);
    expect(s.stampedCheckpointIds, isEmpty);
  });

  test('リセットすると保存データも最初からになる', () async {
    final store = await storeWith({});
    AppState(store: store)
      ..checkIn(findShopById('shop1')!)
      ..resetProgress();
    expect(AppState(store: store).stampedCheckpointIds, isEmpty);
  });

  test('全地点のスタンプがそろったら達成になる', () {
    final s = AppState();
    for (final shop in shops) {
      expect(s.allStamped, false);
      s.checkIn(shop);
    }
    expect(s.allStamped, true);
    expect(s.unstampedCheckpoints, isEmpty);
  });
}
