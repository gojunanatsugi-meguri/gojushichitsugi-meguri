// QR読取 → クイズ → クーポン選択の画面の流れのテスト。
// 以前は2か所目のクイズが答えられなかった（前の回答結果が画面に残っていた）ので、その再発防止も兼ねる

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';

Future<void> scanDemo(WidgetTester tester, String shopName) async {
  await tester.tap(find.byIcon(Icons.qr_code_scanner));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('$shopName（'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1か所目で正解してクーポンを選び、2か所目のクイズにも答えられる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GojushichitsugiApp());

    await scanDemo(tester, '枚方涼氷');
    expect(find.text('第1地点のスタンプを獲得しました！'), findsOneWidget);

    await tester.tap(find.text('ヒントを見る'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ヒント：'), findsOneWidget);

    await tester.tap(find.text('KAORU'));
    await tester.pumpAndSettle();
    expect(find.text('正解です！'), findsOneWidget);

    await tester.tap(find.textContaining('KAORU COFFEE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('これにする'));
    await tester.pumpAndSettle();
    expect(find.text('「KAORU COFFEE」のクーポンをもらいました。'), findsOneWidget);

    await scanDemo(tester, 'KAORU COFFEE');
    expect(find.text('第2地点のスタンプを獲得しました！'), findsOneWidget);
    // 地点が変わったのでヒントは閉じた状態に戻っている
    expect(find.text('ヒントを見る'), findsOneWidget);

    await tester.tap(find.text('本屋'));
    await tester.pumpAndSettle();
    expect(find.text('残念、不正解でした。'), findsOneWidget);
    expect(find.text('スタンプはもらえています。次の地点へ進みましょう。'), findsOneWidget);
  });
}
