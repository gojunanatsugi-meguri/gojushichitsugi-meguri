// スタート画面 → 名前の入力 → スタンプ帳（ホーム）と、起動時の画面の流れのテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gojushichitsugi_meguri/main.dart';
import 'package:gojushichitsugi_meguri/services/progress_store.dart';

// スタート画面から名前を入力して、スタンプ帳まで進む（ほかのテストでも使う）
Future<void> startWithName(WidgetTester tester, String name) async {
  await tester.tap(find.text('はじめる'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), name);
  await tester.pump();
  await tester.tap(find.text('これではじめる'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('初めて起動すると、スタート画面 → 名前の入力 → スタンプ帳の順に進む', (tester) async {
    await tester.pumpWidget(const GojushichitsugiApp());

    expect(find.text('五十七次'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    expect(find.text('はじめる'), findsOneWidget);

    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(find.text('お名前を教えてください'), findsOneWidget);

    // 空白だけでは進めない
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.text('これではじめる'));
    await tester.pumpAndSettle();
    expect(find.text('お名前を教えてください'), findsOneWidget);

    await tester.enterText(find.byType(TextField), ' ひらかた ');
    await tester.pump();
    await tester.tap(find.text('これではじめる'));
    await tester.pumpAndSettle();
    expect(find.text('スタンプ帳（0 / 5）'), findsOneWidget);
    expect(find.text('ひらかたさん、枚方宿を歩いて、宿場印を集めよう。'), findsOneWidget);
  });

  testWidgets('名前を入力済みなら、「はじめる」でそのままスタンプ帳へ進む', (tester) async {
    SharedPreferences.setMockInitialValues({'meguri_player_name_v1': 'ひらかた'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(GojushichitsugiApp(store: ProgressStore(prefs)));

    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(find.text('スタンプ帳（0 / 5）'), findsOneWidget);
  });

  testWidgets('設定ボタンから名前を変えると、スタート画面に戻る', (tester) async {
    SharedPreferences.setMockInitialValues({'meguri_player_name_v1': 'ひらかた'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(GojushichitsugiApp(store: ProgressStore(prefs)));
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('ひらかた'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'くずは');
    await tester.pump();
    await tester.tap(find.text('この名前にする'));
    await tester.pumpAndSettle();
    expect(find.text('はじめる'), findsOneWidget);
    expect(prefs.getString('meguri_player_name_v1'), 'くずは');
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
