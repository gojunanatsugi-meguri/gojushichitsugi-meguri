// クイズの問題の画面のテスト（番号付きの選択肢・「あとで」・小さい画面）

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';

import 'quiz_flow_test.dart' show scanDemo;
import 'widget_test.dart' show startApp;

// 縦長の画面にして、スタンプ獲得の画面の「クイズに進む」まで見えるようにする
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openQuiz(WidgetTester tester) async {
  await scanDemo(tester, '枚方凍氷');
  await tester.tap(find.text('クイズに進む'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('問題の札・何番目の地点か・1から始まる番号付きの選択肢が出る', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openQuiz(tester);

    expect(find.text('問題'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    for (final n in ['1', '2', '3']) {
      expect(find.text(n), findsOneWidget);
    }
  });

  testWidgets('「あとで」で地図に戻り、地図の案内からクイズに戻れる', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openQuiz(tester);

    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    expect(find.text('クイズにまだ答えていません'), findsOneWidget);

    await tester.tap(find.text('クイズにまだ答えていません'));
    await tester.pumpAndSettle();
    expect(find.text('問題'), findsOneWidget);
  });

  testWidgets('ヒントは下から目の前に出て、閉じたあとも何度でも開ける', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openQuiz(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('ヒント'));
      await tester.pumpAndSettle();
      expect(find.text('お店の看板をよく見てみましょう。'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // カードの外を押して閉じる
      await tester.pumpAndSettle();
      expect(find.text('お店の看板をよく見てみましょう。'), findsNothing);
    }
  });

  testWidgets('小さい画面（iPhone SE）でも、クイズの画面とヒントがはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openQuiz(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ヒント'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
