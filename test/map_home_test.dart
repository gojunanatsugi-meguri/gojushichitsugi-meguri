// ホーム（地図）の画面のテスト。
// 以前は「地点の一覧」を開くと、一覧の行の配置がエラーになって画面が固まっていたので、その再発防止も兼ねる

import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/main.dart';

import 'widget_test.dart' show startWithName;

void main() {
  testWidgets('「地点の一覧」を開いて、地点を選ぶと一覧が閉じる', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());
    await startWithName(tester, 'ひらかた');

    await tester.tap(find.text('地点の一覧'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('第5地点'), findsOneWidget);

    await tester.tap(find.text('第5地点'));
    await tester.pumpAndSettle();
    expect(find.text('第5地点'), findsNothing);
    expect(find.text('次の目的地'), findsOneWidget);
  });
}
