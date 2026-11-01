import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'coupons_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'quiz_screen.dart';
import 'scan_screen.dart';

// 下タブでホーム（地図）・スタンプ帳・QR読取・クーポンを切り替える。
// 画面の番号（goToTab の番号）は今までどおり 0:スタンプ帳 1:QR読取 2:クイズ 3:クーポン 4:地図 のまま。
// クイズはQRを読んだあとに出るので、タブには並べない
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  static const _screens = [
    HomeScreen(),
    ScanScreen(),
    QuizScreen(),
    CouponsScreen(),
    MapScreen(),
  ];

  // タブの並び → 画面の番号
  static const _tabScreens = [4, 0, 1, 3];

  // クイズを表示している間は、その前の「QR読取」のタブを選択中にしておく
  static int _selectedTab(int screen) {
    final i = _tabScreens.indexOf(screen == 2 ? 1 : screen);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: IndexedStack(index: appState.currentTabIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab(appState.currentTabIndex),
        onDestinationSelected: (i) => appState.goToTab(_tabScreens[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'スタンプ帳'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'QR読取'),
          NavigationDestination(icon: Icon(Icons.confirmation_number), label: 'クーポン'),
        ],
      ),
    );
  }
}
