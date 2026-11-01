import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'stamp_get_screen.dart';

// 回答結果は AppState に地点ごとに記録する。この画面は IndexedStack で
// 破棄されずに残るため、画面側に持つと前の地点の結果が残ってしまう
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cp = findCheckpointById(appState.lastScannedCheckpointId);

    // key を地点IDにすると、地点が変わったときに _QuizBody の状態（ヒント表示など）が作り直される
    if (cp != null) return _QuizBody(key: ValueKey(cp.id), checkpoint: cp);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('クイズ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
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
            ),
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
  // QRを読んだ直後は、スタンプを獲得した画面を出し、「クイズに進む」を押してから問題を出す
  bool showQuiz = false;

  // ヒントは選択肢の下に出すと画面の外に隠れてしまうので、下から出して目の前に見せる。何度でも開ける。
  // 閉じるときは、カードの外を押すか、下に引く
  void _showHint(Quiz quiz) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: AppColors.gold, size: 30),
                  const SizedBox(width: 8),
                  Text('ヒント', style: minchoStyle.copyWith(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 12),
              Text(quiz.hint, style: const TextStyle(fontSize: 20, height: 1.5, color: AppColors.ink)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

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
    final result = appState.quizResults[cp.id];

    // QRを読んだ直後（まだ答えていない）と、クイズのない最後の地点は、スタンプ獲得の画面を出す
    if (quiz == null || (result == null && !showQuiz)) {
      return StampGetScreen(
        checkpoint: cp,
        onQuiz: quiz == null ? null : () => setState(() => showQuiz = true),
      );
    }

    if (result == null) return _question(appState, cp, quiz);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            _TopBar(checkpoint: cp),
            const SizedBox(height: 8),
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
            _quizContent(appState, cp, quiz, result),
          ],
        ),
      ),
    );
  }

  // まだ答えていない：問題を出す。問題のカード → 1・2・3 の選択肢 → 下に「ヒント」「あとで」
  Widget _question(AppState appState, Checkpoint cp, Quiz quiz) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _TopBar(checkpoint: cp)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                children: [
                  _QuestionCard(quiz: quiz),
                  const SizedBox(height: 8),
                  const Text('答えは、次の地点のまわりにあります。',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.inkSoft)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < quiz.options.length; i++) ...[
                    _OptionButton(
                      number: i + 1,
                      label: quiz.options[i],
                      onPressed: () => appState.answerQuiz(cp.id, quiz.options[i]),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _SmallButton(
                      icon: Icons.lightbulb_outline,
                      label: 'ヒント',
                      onPressed: () => _showHint(quiz),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 答えずに地図へ戻る。地図には「クイズにまだ答えていません」の案内が出て、そこから戻れる
                  Expanded(
                    child: _SmallButton(icon: Icons.schedule, label: 'あとで', onPressed: () => appState.goToTab(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 答えたあとの中身（不正解・クーポン選び）
  Widget _quizContent(AppState appState, Checkpoint cp, Quiz quiz, bool result) {
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

// 上の帯。左に「何番目の地点のクイズか」を出す（右上は設定ボタンの場所なので空けておく）
class _TopBar extends StatelessWidget {
  const _TopBar({required this.checkpoint});

  final Checkpoint checkpoint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 56, 8),
      child: Row(
        children: [
          Text('クイズ', style: minchoStyle.copyWith(fontSize: 26)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.indigoDeep, borderRadius: BorderRadius.circular(8)),
            child: Text('${checkpoint.order}/${checkpoints.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// 「問題」の札と、明朝体の問題文。絵がある問題は下に絵を出す
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            color: AppColors.indigoDeep,
            child: const Text('問題',
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 4)),
          ),
          const SizedBox(height: 12),
          Text(quiz.question, textAlign: TextAlign.center, style: minchoStyle.copyWith(fontSize: 24, height: 1.4)),
          const SizedBox(height: 14),
          // 絵は横長（16:9）の枠に入れる。絵がまだない問題と、ファイルが見つからないときは白い枠を出す
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: switch (quiz.image) {
                final image? => Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _NoImage()),
                null => const _NoImage(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 絵の代わりの白い枠
class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: const Center(child: Icon(Icons.image_outlined, color: AppColors.line, size: 48)),
    );
  }
}

// 左に紺の丸と番号、右に選択肢の文
class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.number, required this.label, required this.onPressed});

  final int number;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.indigoDeep,
                child: Text('$number', style: minchoStyle.copyWith(fontSize: 20, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: minchoStyle.copyWith(fontSize: 20))),
            ],
          ),
        ),
      ),
    );
  }
}

// 下の「ヒント」「あとで」の小さめのボタン
class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.ink, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 18, color: AppColors.ink)),
      ),
    );
  }
}
