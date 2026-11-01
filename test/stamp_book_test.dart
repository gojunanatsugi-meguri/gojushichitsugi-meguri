// スタンプ帳（図鑑）の画面のテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';
import 'package:gojushichitsugi_meguri/widgets/stamp_mark.dart';

import 'quiz_flow_test.dart' show scanDemo;
import 'widget_test.dart' show startWithName;

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
    await startWithName(tester, 'ひらかた');
    await openStampBook(tester);

    expect(find.text('？'), findsNWidgets(5));
    // 画面全体のスクロール（中の図鑑の一覧もスクロールの部品なので、外側を指定する）
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('スタンプを全部集めると手に入ります'), 300, scrollable: page);
    expect(find.text('スタンプを全部集めると手に入ります'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No.01'), -300, scrollable: page);

    await tester.tap(find.text('No.01'));
    await tester.pumpAndSettle();
    expect(find.text('お店のQRを読むと、スタンプが押されます。'), findsOneWidget);
  });

  testWidgets('QRを読むと、その地点のスタンプが押されて、詳しい内容にお店が出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startWithName(tester, 'ひらかた');
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

  testWidgets('QRを読むと、獲得の画面にスタンプが押される動きつきで出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startWithName(tester, 'ひらかた');
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
    expect(find.text('ヒントを見る'), findsNothing);
    await tester.tap(find.text('クイズに進む'));
    await tester.pumpAndSettle();
    expect(find.text('ヒントを見る'), findsOneWidget);
    expect(find.byType(StampPress), findsNothing);
  });

  testWidgets('スタンプ獲得の画面の歯車から、設定画面で名前を変えられる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startWithName(tester, 'ひらかた');
    await scanDemo(tester, '枚方凍氷');

    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();
    expect(find.text('ひらかた'), findsOneWidget);

    await tester.tap(find.text('お名前'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'くずは');
    await tester.pump();
    await tester.tap(find.text('この名前にする'));
    await tester.pumpAndSettle();
    expect(find.text('くずは'), findsOneWidget);
  });

  testWidgets('小さい画面（iPhone SE）でも、スタンプ獲得の画面がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startWithName(tester, 'ひらかた');
    await scanDemo(tester, '枚方凍氷');
    expect(tester.takeException(), isNull);
  });

  testWidgets('小さい画面（iPhone SE）でも、スタンプ帳がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startWithName(tester, 'ひらかた');
    await openStampBook(tester);
    expect(tester.takeException(), isNull);
  });
}
