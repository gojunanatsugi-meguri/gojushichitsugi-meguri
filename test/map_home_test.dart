// ホーム（地図）の画面のテスト。
// 以前は地点の一覧を開くと、一覧の行の配置がエラーになって画面が固まっていたので、その再発防止も兼ねる

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';

import 'quiz_flow_test.dart' show scanDemo;
import 'widget_test.dart' show startApp;

// 左上の「枚方宿」のカードを押して、地点の一覧を開く・閉じる
Future<void> toggleList(WidgetTester tester) async {
  await tester.tap(find.text('枚方宿'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('開いた直後は、下のカードを出さない', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    expect(find.text('次の目的地'), findsNothing);
    expect(find.text('QRを読み取る'), findsNothing);
  });

  testWidgets('設定ボタンは、ホームにはなく、ほかのタブの画面にはある', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    expect(find.byTooltip('設定'), findsNothing);

    for (final icon in [Icons.menu_book, Icons.qr_code_scanner, Icons.confirmation_number]) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      expect(find.byTooltip('設定'), findsOneWidget);
    }
  });

  testWidgets('「枚方宿」のカードを押すたびに、地点の一覧が開いたり閉じたりする', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);

    await toggleList(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('くらわんか餅巴堂'), findsOneWidget);

    await toggleList(tester);
    expect(find.text('くらわんか餅巴堂'), findsNothing);
  });

  testWidgets('一覧で地点を選ぶと下のカードが出て、×で閉じる', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);

    await toggleList(tester);
    await tester.tap(find.text('くらわんか餅巴堂'));
    await tester.pumpAndSettle();
    expect(find.text('選んだ地点'), findsOneWidget);
    expect(find.text('第5地点・餅菓子'), findsOneWidget);
    // 一覧は閉じて、下のカードと地図の吹き出しの両方に名前が出る
    expect(find.text('くらわんか餅巴堂'), findsNWidgets(2));

    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('選んだ地点'), findsNothing);
    expect(find.text('QRを読み取る'), findsNothing);
  });

  testWidgets('次の地点を選ぶと「次の目的地」、ほかのまだの地点は「選んだ地点」、行った地点は「スタンプ済みの地点」', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);

    await toggleList(tester);
    await tester.tap(find.text('枚方凍氷'));
    await tester.pumpAndSettle();
    expect(find.text('次の目的地'), findsOneWidget);

    await toggleList(tester);
    await tester.tap(find.text('くらわんか餅巴堂'));
    await tester.pumpAndSettle();
    expect(find.text('選んだ地点'), findsOneWidget);

    await scanDemo(tester, 'くらわんか餅巴堂');
    await tester.tap(find.byIcon(Icons.map));
    await tester.pumpAndSettle();
    expect(find.text('スタンプ済みの地点'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsWidgets);
  });

  testWidgets('現在地が分からないときは、歩数の代わりに現在地の出し方を案内する', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);

    await toggleList(tester);
    await tester.tap(find.text('枚方凍氷'));
    await tester.pumpAndSettle();
    expect(find.text('右上の ◎ で現在地を出すと、ここまでの歩数が分かります'), findsOneWidget);
  });

  testWidgets('小さい画面（iPhone SE）でも、一覧と下のカードがはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await toggleList(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('うつわとカフェ Lau'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
