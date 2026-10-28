// クーポンの「使用済み」のテスト。一度使ったクーポンは元に戻らないことを確かめる

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gojushichitsugi_meguri/main.dart';
import 'package:gojushichitsugi_meguri/models/app_state.dart';
import 'package:gojushichitsugi_meguri/services/progress_store.dart';

import 'quiz_flow_test.dart' show scanDemo;
import 'widget_test.dart' show startWithName;

// 第1地点で正解して、KAORU COFFEE（shop2）のクーポンを持っている状態を作る
AppState stateWithCoupon({ProgressStore? store}) {
  return AppState(store: store)
    ..checkIn(findShopById('shop1')!)
    ..answerQuiz('cp1', 'KAORU')
    ..chooseCoupon('cp1', 'shop2');
}

void main() {
  test('持っているクーポンは使える。使った日時が残る', () {
    final s = stateWithCoupon();
    final at = DateTime(2027, 1, 27, 11, 5);
    s.useCoupon('shop2', now: at);
    expect(s.isCouponUsed('shop2'), true);
    expect(s.couponUsedAt['shop2'], at);
  });

  test('持っていないクーポンは使えない', () {
    final s = stateWithCoupon();
    s.useCoupon('shop3');
    expect(s.couponUsedAt, isEmpty);
  });

  test('2回使っても、最初に使った日時のまま', () {
    final s = stateWithCoupon();
    final first = DateTime(2027, 1, 27, 11, 5);
    s.useCoupon('shop2', now: first);
    s.useCoupon('shop2', now: DateTime(2027, 1, 27, 15, 0));
    expect(s.couponUsedAt['shop2'], first);
  });

  test('アプリを開き直しても、使用済みのまま（復活しない）', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProgressStore(await SharedPreferences.getInstance());
    stateWithCoupon(store: store).useCoupon('shop2', now: DateTime(2027, 1, 27, 11, 5));

    final reopened = AppState(store: store);
    expect(reopened.isCouponUsed('shop2'), true);
  });

  test('開発用のリセットで、使用済みも消える', () {
    final s = stateWithCoupon()..useCoupon('shop2');
    s.resetProgress();
    expect(s.couponUsedAt, isEmpty);
  });

  testWidgets('クーポン画面で「使う」を押すと確認が出て、使用済みになる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startWithName(tester, 'テスト');

    // 第1地点で正解して KAORU COFFEE のクーポンをもらう
    await scanDemo(tester, '枚方涼氷');
    await tester.tap(find.text('KAORU'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('KAORU COFFEE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('これにする'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.confirmation_number));
    await tester.pumpAndSettle();
    expect(find.text('このクーポンを使う'), findsOneWidget);

    // 「戻る」を押したら、使われない
    await tester.tap(find.text('このクーポンを使う'));
    await tester.pumpAndSettle();
    expect(find.text('お店の方の前で押してください。\n使ったクーポンは元に戻せません。'), findsOneWidget);
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('このクーポンを使う'), findsOneWidget);

    // 「使う」を押したら、使用済みになり、ボタンが消える
    await tester.tap(find.text('このクーポンを使う'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('使う'));
    await tester.pumpAndSettle();
    expect(find.textContaining('使用済み（'), findsOneWidget);
    expect(find.text('このクーポンを使う'), findsNothing);
  });
}
