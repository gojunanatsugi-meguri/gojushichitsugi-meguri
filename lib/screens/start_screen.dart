import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../theme.dart';
import 'name_screen.dart';
import 'root_screen.dart';

// 下タブの番号（root_screen.dart の並びと同じ）
const _tabHome = 0;
const _tabCoupons = 3;

// 筆文字が入っていない端末でも、明朝の太字で和の雰囲気を出す
const _mincho = TextStyle(
  fontFamily: 'Hiragino Mincho ProN',
  fontFamilyFallback: ['Yu Mincho', 'Noto Serif JP', 'serif'],
  fontWeight: FontWeight.w900,
  color: AppColors.ink,
);

// アプリを開くと毎回最初に出る画面。
// 名前が未入力なら名前の入力へ、入力済みならそのまま各画面へ進む
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _open(BuildContext context, int tab) {
    final appState = context.read<AppState>()..goToTab(tab);
    if (appState.hasPlayerName) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RootScreen()));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NameScreen()));
    }
  }

  void _showHowTo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (_) => const _HowToSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: '名前の変更',
                  icon: const Icon(Icons.settings, color: AppColors.inkSoft),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NameScreen(editing: true))),
                ),
              ),
              const _Title(),
              const SizedBox(height: 10),
              Text('― 街を巡って、歴史をたどる ―', style: _mincho.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Expanded(child: _HeroPlaceholder()),
              const SizedBox(height: 12),
              _StatsCard(appState: appState),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.indigoDeep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _open(context, _tabHome),
                  icon: const Icon(Icons.storefront, size: 30),
                  label: Text('はじめる', style: _mincho.copyWith(fontSize: 26, color: Colors.white, letterSpacing: 4)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SubButton(
                      icon: Icons.menu_book,
                      label: '集めたもの',
                      onPressed: () => _open(context, _tabCoupons),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SubButton(icon: Icons.help_outline, label: '使い方', onPressed: () => _showHowTo(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 「五十七次めぐり」の題字。後ろに朱色の筆の丸、右に「枚方宿」の印
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomPaint(
            painter: const _BrushCirclePainter(),
            child: Column(
              children: [
                Text('五十七次', style: _mincho.copyWith(fontSize: 52, height: 1.15)),
                Text('めぐり', style: _mincho.copyWith(fontSize: 52, height: 1.15)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.shu, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                for (final c in ['枚', '方', '宿'])
                  Text(c, style: _mincho.copyWith(fontSize: 20, color: AppColors.shu, height: 1.15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 筆でぐるっと描いたような、閉じきらない朱色の丸
class _BrushCirclePainter extends CustomPainter {
  const _BrushCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 題字の左寄りを中心に、題字より少し大きく描く（題字の外にはみ出してよい）
    final radius = size.height * 0.56;
    final rect = Rect.fromCircle(center: Offset(size.width * 0.38, size.height / 2), radius: radius);
    final paint = Paint()
      // 半透明にすると、細かく分けて描いた継ぎ目が濃く見えるので不透明にする
      ..color = AppColors.shu
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // 太さを少しずつ変えて、筆の入りと抜きを表す
    const steps = 24;
    const start = math.pi * 0.75, sweep = math.pi * 1.7;
    for (var i = 0; i < steps; i++) {
      paint.strokeWidth = 4 + 9 * math.sin(math.pi * i / steps);
      canvas.drawArc(rect, start + sweep * i / steps, sweep / steps + 0.02, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 旅人と町並みのイラストの仮置き。イラストの画像ができたら Image.asset に差し替える
class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFEDE3D0), borderRadius: BorderRadius.circular(12)),
      child: const CustomPaint(
        painter: _RooftopsPainter(),
        child: Center(child: Icon(Icons.directions_walk, size: 96, color: AppColors.indigoDeep)),
      ),
    );
  }
}

// 宿場町の屋根並みを線で描く
class _RooftopsPainter extends CustomPainter {
  const _RooftopsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkSoft.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final ground = size.height * 0.82;
    canvas.drawLine(Offset(0, ground), Offset(size.width, ground), paint);
    for (final side in [0.0, 1.0]) {
      // 左右に2軒ずつ。中央の旅人にかからないよう端に寄せる
      for (var i = 0; i < 2; i++) {
        final w = size.width * 0.17;
        final x = side == 0 ? 8 + i * (w + 6) : size.width - 8 - (i + 1) * w - i * 6;
        final roof = ground - size.height * (0.42 + 0.08 * i);
        final path = Path()
          ..moveTo(x - 6, roof + 18)
          ..lineTo(x + w / 2, roof)
          ..lineTo(x + w + 6, roof + 18)
          ..moveTo(x, roof + 14)
          ..lineTo(x, ground)
          ..moveTo(x + w, roof + 14)
          ..lineTo(x + w, ground);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 進捗・今の位・本日の歩数
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.place_outlined, '進捗', '${appState.stampedCheckpointIds.length}/${checkpoints.length}'),
      (Icons.workspace_premium_outlined, '今の位', appState.currentRank.label),
      // 歩数の取得ができるまでは表示しない
      (Icons.directions_walk, '本日', '— 歩'),
    ];

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 44, color: AppColors.line),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].$1, size: 18, color: AppColors.shu),
                      const SizedBox(width: 4),
                      Text(items[i].$2, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(items[i].$3, style: _mincho.copyWith(fontSize: 22, height: 1.2)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubButton extends StatelessWidget {
  const _SubButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.indigoDeep,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 18, color: AppColors.ink)),
      ),
    );
  }
}

// 「使い方」：めぐりの流れを3つの段階で説明する
class _HowToSheet extends StatelessWidget {
  const _HowToSheet();

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
            Text('使い方', style: _mincho.copyWith(fontSize: 24)),
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
