// QR読取の画面のテスト（見た目の並びと「うまく読み取れない場合」）

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';

import 'widget_test.dart' show startApp;

Future<void> openScan(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.qr_code_scanner));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('開くとすぐ案内と読み取りの画面が出て、「カメラで読み取る」ボタンは押さなくてよい', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openScan(tester);

    expect(find.text('地点のQRコードを写してください'), findsOneWidget);
    expect(find.text('うまく読み取れない場合'), findsOneWidget);
    expect(find.text('カメラでQRを読み取る'), findsNothing);
  });

  testWidgets('「うまく読み取れない場合」で、読み取りのコツが出る', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openScan(tester);

    await tester.tap(find.text('うまく読み取れない場合'));
    await tester.pumpAndSettle();
    expect(find.text('それでも読めないときは、近くのお店の方や係の人に声をかけてください。'), findsOneWidget);
  });

  testWidgets('小さい画面（iPhone SE）でも、QR読取の画面と説明がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());
    await startApp(tester);
    await openScan(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('うまく読み取れない場合'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
