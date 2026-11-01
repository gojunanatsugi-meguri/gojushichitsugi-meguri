import 'package:flutter/material.dart';

import '../theme.dart';

// 「使い方」を下から出す。スタート画面と設定画面の両方から開く
void showHowTo(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    showDragHandle: true,
    builder: (_) => const HowToSheet(),
  );
}

// めぐりの流れを3つの段階で説明する
class HowToSheet extends StatelessWidget {
  const HowToSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('協力店のQRを読む', '着いたしるしにスタンプがもらえます。'),
      ('クイズに答える', '答えは「次の地点の周辺」にあります。ヒントはいつでも見られます。'),
      ('クーポンを選ぶ', '正解すると、次の地点のお店から1店を選んでクーポンがもらえます。'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('使い方', style: minchoStyle.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.indigoDeep,
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(steps[i].$2, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
