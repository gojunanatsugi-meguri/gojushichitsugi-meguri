import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

// 回答結果は AppState に地点ごとに記録する。この画面は IndexedStack で
// 破棄されずに残るため、画面側に持つと前の地点の結果が残ってしまう
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cp = findCheckpointById(appState.lastScannedCheckpointId);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('クイズ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            if (cp == null)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('まだQRを読み取っていません。先にお店のQRを読み取って、スタンプをもらいましょう。',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 16),
                    BigButton(label: 'QR読取へ進む', filled: true, onPressed: () => appState.goToTab(1)),
                  ],
                ),
              )
            else ...[
              // 宿場印との引き換え画面ができるまでは、達成したことだけを伝える
              if (appState.allStamped) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12)),
                  child: const Text('全地点のスタンプがそろいました！\n宿場印と引き換えられます。',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 16),
              ],
              // key を地点IDにすると、地点が変わったときに _QuizBody の状態（ヒント表示など）が作り直される
              _QuizBody(key: ValueKey(cp.id), checkpoint: cp),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizBody extends StatefulWidget {
  const _QuizBody({super.key, required this.checkpoint});

  final Checkpoint checkpoint;

  @override
  State<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends State<_QuizBody> {
  bool showHint = false;

  // クーポンは1問につき1店だけで、選び直しができないので確認をはさむ
  Future<void> _confirmCoupon(Shop shop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('「${shop.name}」のクーポンにしますか？\n選んだあとは変えられません。', style: const TextStyle(fontSize: 20)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('戻る', style: TextStyle(fontSize: 18))),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('これにする', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AppState>().chooseCoupon(widget.checkpoint.id, shop.id);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cp = widget.checkpoint;
    final quiz = cp.quiz;
    final stampText = Text('${cp.name}のスタンプを獲得しました！',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.indigo));

    // 最後の地点：クイズはなし
    if (quiz == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stampText,
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('最後の地点です。おつかれさまでした！', style: TextStyle(fontSize: 20)),
                // 順番どおりに回らなかった人もいるので、残りの地点を伝える
                if (!appState.allStamped) ...[
                  const SizedBox(height: 8),
                  Text('まだスタンプがない地点：${appState.unstampedCheckpoints.map((c) => c.name).join('、')}',
                      style: const TextStyle(fontSize: 18, color: AppColors.inkSoft)),
                ],
                const SizedBox(height: 16),
                BigButton(label: 'スタンプ帳を見る', filled: true, onPressed: () => appState.goToTab(0)),
              ],
            ),
          ),
        ],
      );
    }

    final result = appState.quizResults[cp.id];

    // まだ答えていない：問題を出す
    if (result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stampText,
          const SizedBox(height: 4),
          const Text('答えは、次の地点のまわりにあります。', style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                for (final opt in quiz.options) ...[
                  BigButton(label: opt, onPressed: () => appState.answerQuiz(cp.id, opt)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                if (showHint)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(10)),
                    child: Text('ヒント：${quiz.hint}', style: const TextStyle(fontSize: 18)),
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => showHint = true),
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('ヒントを見る', style: TextStyle(fontSize: 18)),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // 不正解：スタンプはもらえているので、先へ進めることをはっきり伝える
    if (result == false) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('残念、不正解でした。', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('正解は「${quiz.correctAnswer}」です。', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text('スタンプはもらえています。次の地点へ進みましょう。', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            BigButton(label: '地図を見る', filled: true, onPressed: () => appState.goToTab(4)),
            const SizedBox(height: 10),
            BigButton(label: 'スタンプ帳に戻る', onPressed: () => appState.goToTab(0)),
          ],
        ),
      );
    }

    // 正解してクーポンを選び終えた
    final chosen = findShopById(appState.couponChoices[cp.id] ?? '');
    if (chosen != null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${chosen.name}」のクーポンをもらいました。', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(chosen.coupon, style: const TextStyle(fontSize: 20, color: AppColors.indigo)),
            const SizedBox(height: 16),
            BigButton(label: 'クーポンを見る', filled: true, onPressed: () => appState.goToTab(3)),
            const SizedBox(height: 10),
            BigButton(label: '地図を見る', onPressed: () => appState.goToTab(4)),
          ],
        ),
      );
    }

    // 正解：次の地点の協力店から1店を選ぶ
    final candidates = appState.couponCandidates(cp.id);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('正解です！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.gold)),
          const SizedBox(height: 8),
          const Text('次の地点のお店から、クーポンを1つ選んでください。', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          if (candidates.isEmpty)
            const Text('選べるクーポンがありません。', style: TextStyle(fontSize: 18, color: AppColors.inkSoft))
          else
            for (final shop in candidates) ...[
              BigButton(
                label: '${shop.name}\n${shop.coupon}',
                filled: true,
                onPressed: () => _confirmCoupon(shop),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
