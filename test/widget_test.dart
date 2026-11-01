// スタート画面 → ホーム（地図）と、起動時の画面の流れのテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';

// スタート画面の「はじめる」で、ホームまで進む（ほかのテストでも使う）
Future<void> startApp(WidgetTester tester) async {
  await tester.tap(find.text('はじめる'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('初めて起動しても、名前の入力はなく「はじめる」でそのままホームへ進む', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());

    expect(find.text('五十七次'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);

    await startApp(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('枚方宿'), findsOneWidget);
    expect(find.text('スタンプ 0 / 5'), findsOneWidget);

    // スタンプ帳はタブから開ける
    await tester.tap(find.byIcon(Icons.menu_book));
    await tester.pumpAndSettle();
    expect(find.text(' / 5 収集'), findsOneWidget);
  });

  testWidgets('スタート画面の歯車から設定画面が開く', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();
    expect(find.text('使い方を見る'), findsOneWidget);
    expect(find.text('お名前'), findsNothing);
  });

  testWidgets('小さい画面（iPhone SE）でも、スタート画面がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    // はみ出しがあると、ここで例外として報告される
    expect(tester.takeException(), isNull);
    expect(find.text('はじめる'), findsOneWidget);
  });

  testWidgets('「使い方」でめぐりの流れが表示される', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await tester.tap(find.text('使い方'));
    await tester.pumpAndSettle();
    expect(find.text('協力店のQRを読む'), findsOneWidget);
  });
}
