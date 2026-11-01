import 'package:flutter/material.dart';

import '../screens/settings_screen.dart';
import '../theme.dart';

// 画面の上の題字「五十七次めぐり」と「枚方宿」の印、右に設定ボタン。
// 題字の画像ができたら、ここを画像に差し替える
// showTitle: false のときは題字を出さず、設定ボタンだけにする
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // 設定ボタンと同じ幅を左にも取って、題字を真ん中にそろえる
          const SizedBox(width: 48),
          Expanded(
            child: !showTitle
                ? const SizedBox()
                : Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('五十七次めぐり', style: minchoStyle.copyWith(fontSize: 24)),
                          const SizedBox(width: 6),
                          const _Seal(text: '枚方宿'),
                        ],
                      ),
                    ),
                  ),
          ),
          const SettingsButton(),
        ],
      ),
    );
  }
}

// 設定画面を開く歯車のボタン
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings, color: AppColors.indigoDeep, size: 28),
      tooltip: '設定',
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
    );
  }
}

// 縦書きの小さな朱色の印
class _Seal extends StatelessWidget {
  const _Seal({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.shu, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in text.characters)
            Text(c, style: minchoStyle.copyWith(fontSize: 10, color: AppColors.shu, height: 1.1)),
        ],
      ),
    );
  }
}
