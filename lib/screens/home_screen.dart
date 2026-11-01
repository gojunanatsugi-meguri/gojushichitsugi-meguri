import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';

// スタンプ帳。地点ごとのスタンプを図鑑のように並べ、まだのものは空き枠で見せる
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showDetail(BuildContext context, AppState appState, Checkpoint cp) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StampDetail(appState: appState, checkpoint: cp),
    );
  }

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
            const Text('スタンプ帳',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('${appState.hasPlayerName ? '${appState.playerName}さん、' : ''}枚方宿を歩いて、宿場印を集めよう。',
                style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 16),

            _RankCard(appState: appState, rank: rank),

            const SizedBox(height: 20),

            // 集めた数
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('枚方宿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$stampedCount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.shu)),
                Text(' / ${checkpoints.length} 収集', style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: checkpoints.isEmpty ? 0 : stampedCount / checkpoints.length,
                minHeight: 8,
                backgroundColor: AppColors.line,
                color: AppColors.shu,
              ),
            ),
            const SizedBox(height: 16),

            // 図鑑の一覧
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                for (final cp in checkpoints)
                  _StampCard(
                    checkpoint: cp,
                    stampedAt: appState.stampedAt[cp.id],
                    onTap: () => _showDetail(context, appState, cp),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // 宿場印。全部そろうと開く
            _ShukubaCard(completed: appState.allStamped, rank: rank),

            const SizedBox(height: 16),

            // ほかの宿場は、これから増える予定であることだけ見せる
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.line.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.inkSoft),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('五十七次のほかの宿場（伏見宿・淀宿・守口宿など）は、これから追加予定です',
                        style: TextStyle(color: AppColors.inkSoft)),
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

// 位のカード（歩いた距離と位）
class _RankCard extends StatelessWidget {
  const _RankCard({required this.appState, required this.rank});

  final AppState appState;
  final Rank rank;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // 画面が狭いときは2段に折り返す
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => appState.addDemoDistance(10),
                child: const Text('+10km（デモ）'),
              ),
              OutlinedButton(
                onPressed: () => appState.addDemoDistance(50),
                child: const Text('+50km（デモ）'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _kanjiNumbers = ['壱', '弐', '参', '肆', '伍', '陸', '漆', '捌', '玖', '拾'];

String _kanjiNumber(int n) => n >= 1 && n <= _kanjiNumbers.length ? _kanjiNumbers[n - 1] : '$n';

String _dateLabel(DateTime d) => '${d.month}月${d.day}日';

// 押したスタンプの見た目。朱色の二重丸に、地点の番号（漢数字）を入れる。
// 地点ごとに少しずつ傾けて、手で押したように見せる
class _StampMark extends StatelessWidget {
  const _StampMark({required this.order, required this.size});

  final int order;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tilt = [-0.12, 0.08, -0.05, 0.14, -0.09][order % 5];
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.05),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.shu, width: size * 0.04),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.shu, width: size * 0.02),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('枚方宿', style: TextStyle(fontSize: size * 0.13, color: AppColors.shu, fontWeight: FontWeight.w700)),
              Text(_kanjiNumber(order),
                  style: TextStyle(fontSize: size * 0.34, color: AppColors.shu, fontWeight: FontWeight.w900, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

// まだ押していないスタンプの空き枠
class _EmptyMark extends StatelessWidget {
  const _EmptyMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paper,
        border: Border.all(color: AppColors.line, width: 3),
      ),
      child: Text('？', style: TextStyle(fontSize: size * 0.36, color: AppColors.line, fontWeight: FontWeight.w700)),
    );
  }
}

class _StampCard extends StatelessWidget {
  const _StampCard({required this.checkpoint, required this.stampedAt, required this.onTap});

  final Checkpoint checkpoint;
  final DateTime? stampedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final got = stampedAt != null;
    return Material(
      color: got ? Colors.white : Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: got ? AppColors.shu.withValues(alpha: 0.4) : AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('No.${checkpoint.order.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = (c.biggest.shortestSide * 0.9).clamp(40.0, 120.0);
                    return Center(child: got ? _StampMark(order: checkpoint.order, size: size) : _EmptyMark(size: size));
                  },
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(checkpoint.name,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: got ? AppColors.ink : AppColors.inkSoft)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(got ? _dateLabel(stampedAt!) : 'まだ',
                    style: TextStyle(fontSize: 14, color: got ? AppColors.shu : AppColors.inkSoft)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 図鑑の1件を押したときの詳しい内容
class _StampDetail extends StatelessWidget {
  const _StampDetail({required this.appState, required this.checkpoint});

  final AppState appState;
  final Checkpoint checkpoint;

  @override
  Widget build(BuildContext context) {
    final at = appState.stampedAt[checkpoint.id];
    final got = at != null;
    final result = appState.quizResults[checkpoint.id];
    final quizText = checkpoint.quiz == null
        ? null
        : !got
            ? 'スタンプを押すと挑戦できます'
            : result == null
                ? 'まだ答えていません'
                : result
                    ? '正解'
                    : '不正解';

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Center(child: got ? _StampMark(order: checkpoint.order, size: 140) : const _EmptyMark(size: 140)),
          const SizedBox(height: 16),
          Text('No.${checkpoint.order.toString().padLeft(2, '0')}　${checkpoint.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),
          _DetailRow(label: '押した日', value: got ? _dateLabel(at) : 'まだ'),
          _DetailRow(
            label: 'お店',
            value: shopsAt(checkpoint.id).map((s) => '${s.name}（${s.category}）').join('\n'),
          ),
          if (quizText != null) _DetailRow(label: 'クイズ', value: quizText),
          if (!got) ...[
            const SizedBox(height: 12),
            const Text('お店のQRを読むと、スタンプが押されます。',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.inkSoft))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

// 宿場印のカード。全部の地点のスタンプがそろうと開く。
// 色（銅・銀・金）を位によって変えるのは、宿場印の画面で作る予定
class _ShukubaCard extends StatelessWidget {
  const _ShukubaCard({required this.completed, required this.rank});

  final bool completed;
  final Rank rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? Colors.white : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: completed ? AppColors.gold : AppColors.line, width: completed ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed ? rank.color : AppColors.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: completed ? rank.color : AppColors.line, width: 2),
            ),
            child: completed
                ? const Text('枚方', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))
                : const Icon(Icons.lock_outline, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('枚方宿の宿場印', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(completed ? '${rank.label}の位で手に入れました' : 'スタンプを全部集めると手に入ります',
                    style: const TextStyle(color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
