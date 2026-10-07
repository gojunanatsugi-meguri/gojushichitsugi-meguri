import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final rank = appState.currentRank;
    final stampedCount = appState.stampedCheckpointIds.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('五十七次めぐり',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('枚方宿を歩いて、宿場印を集めよう。', style: TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 20),

            // ランクカード
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: rank.color, borderRadius: BorderRadius.circular(999)),
                    child: Text(rank.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  Text('これまで ${appState.distanceKm}km 歩きました（全550km中）'),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: appState.rankProgress / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.line,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('歩数と連動して自動で増える予定（現在はデモ用ボタン）',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => appState.addDemoDistance(10),
                        child: const Text('+10km（デモ）'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => appState.addDemoDistance(50),
                        child: const Text('+50km（デモ）'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // スタンプ帳カード
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('スタンプ帳（$stampedCount / ${checkpoints.length}）',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...checkpoints.map((cp) {
                    final got = appState.stampedCheckpointIds.contains(cp.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Text(got ? '●' : '○', style: TextStyle(fontSize: 20, color: got ? AppColors.gold : AppColors.line)),
                          const SizedBox(width: 10),
                          Text(cp.name),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => appState.goToTab(1),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('QRを読み取りに行く'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
