import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('地図', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('現在地とスポットの位置だけを表示するシンプルな地図（位置情報はこの表示だけに使用）。',
                style: TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 16),

            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(10)),
              child: const Text('⚫︎ 実際の地図は Google Maps 等と連携予定（川村さんタスク）',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkSoft)),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('スポット一覧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...checkpoints.map((cp) {
                    final got = appState.stampedCheckpointIds.contains(cp.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Text(got ? '●' : '○', style: TextStyle(fontSize: 20, color: got ? AppColors.gold : AppColors.line)),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${cp.name}：${shopsAt(cp.id).map((s) => s.name).join('、')}')),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
