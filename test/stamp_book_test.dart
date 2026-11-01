// スタンプ帳（図鑑）の画面のテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';
import 'package:gojushichitsugi_meguri/widgets/stamp_mark.dart';

import 'quiz_flow_test.dart' show scanDemo;
import 'widget_test.dart' show startApp;

Future<void> openStampBook(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu_book));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('まだのスタンプは空き枠で並び、押すと集め方が出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openStampBook(tester);

    expect(find.text('？'), findsNWidgets(5));
    // 画面全体のスクロール（中の図鑑の一覧もスクロールの部品なので、外側を指定する）
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('スタンプを全部集めると手に入ります'), 300, scrollable: page);
    expect(find.text('スタンプを全部集めると手に入ります'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No.01'), -300, scrollable: page);

    await tester.tap(find.text('No.01'));
    await tester.pumpAndSettle();
    expect(find.text('地点のQRを読むと、スタンプが押されます。'), findsOneWidget);
  });

  testWidgets('QRを読むと、その地点のスタンプが押されて、詳しい内容にお店が出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await scanDemo(tester, '枚方凍氷');
    await openStampBook(tester);

    expect(find.text('？'), findsNWidgets(4));
    expect(find.text('壱'), findsOneWidget);

    await tester.tap(find.text('No.01'));
    await tester.pumpAndSettle();
    expect(find.text('No.01　枚方凍氷'), findsOneWidget);
    expect(find.text('かき氷'), findsOneWidget);
    expect(find.text('まだ答えていません'), findsOneWidget);
  });

  testWidgets('答えたクイズは、スタンプ帳で問題と答えをもう一度見られる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await scanDemo(tester, '枚方凍氷');
    await tester.tap(find.text('クイズに進む'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAKURA'));
    await tester.pumpAndSettle();

    await openStampBook(tester);
    await tester.tap(find.text('No.01'));
    await tester.pumpAndSettle();
    expect(find.text('不正解'), findsOneWidget);
    expect(find.textContaining('名前に入っている言葉は？'), findsOneWidget);
    expect(find.text('KAORU（解答）'), findsOneWidget);
    expect(find.text('まだ答えていません'), findsNothing);
  });

  testWidgets('QRを読むと、獲得の画面にスタンプが押される動きつきで出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await scanDemo(tester, '枚方凍氷');

    expect(find.byType(StampPress), findsOneWidget);
    // 動きが終わると、押した状態で止まっている
    final opacity = tester.widget<Opacity>(
      find.descendant(of: find.byType(StampPress), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 1);
    expect(find.text('壱'), findsOneWidget);
    expect(find.text('スタンプ獲得！'), findsOneWidget);
    expect(find.text('枚方凍氷'), findsOneWidget);

    // クイズは別の画面。「クイズに進む」を押すまで問題は出ない
    expect(find.text('ヒント'), findsNothing);
    await tester.tap(find.text('クイズに進む'));
    await tester.pumpAndSettle();
    expect(find.text('ヒント'), findsOneWidget);
    expect(find.byType(StampPress), findsNothing);
  });

  testWidgets('スタンプ獲得の画面の歯車から設定画面が開き、使い方・位置情報・歩数・情報の扱いを見られる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await scanDemo(tester, '枚方凍氷');

    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();
    // 位置情報の状態はスマホに問い合わせるので、テストでは行があることだけを確かめる
    expect(find.text('位置情報'), findsOneWidget);
    expect(find.text('今日の歩数：0歩'), findsOneWidget);
    expect(find.text('© OpenStreetMap の協力者'), findsOneWidget);

    await tester.tap(find.text('使い方を見る'));
    await tester.pumpAndSettle();
    expect(find.text('協力店のQRを読む'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('情報の扱いについて'));
    await tester.pumpAndSettle();
    expect(find.text('めぐりの記録'), findsOneWidget);
  });

  testWidgets('小さい画面（iPhone SE）でも、設定画面がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('小さい画面（iPhone SE）でも、スタンプ獲得の画面がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await scanDemo(tester, '枚方凍氷');
    expect(tester.takeException(), isNull);
  });

  testWidgets('小さい画面（iPhone SE）でも、スタンプ帳がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openStampBook(tester);
    expect(tester.takeException(), isNull);
  });
}
