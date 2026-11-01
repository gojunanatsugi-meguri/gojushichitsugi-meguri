import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/route_guide.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/stamp_mark.dart';

// スタンプを獲得したときの画面（QRを読んだ直後に出る）。
// 後ろに放射状の光と紙吹雪を描き、スタンプが押される動きを見せる。
// onQuiz があれば「クイズに進む」を一番目立つボタンにする。最後の地点（クイズなし）は null
class StampGetScreen extends StatelessWidget {
  const StampGetScreen({super.key, required this.checkpoint, this.onQuiz});

  final Checkpoint checkpoint;
  final VoidCallback? onQuiz;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cp = checkpoint;
    // 小さい画面でもボタンまで見えるよう、スタンプの大きさを画面の高さに合わせる
    final stampSize = (MediaQuery.of(context).size.height * 0.18).clamp(100.0, 150.0);

    // 下のメッセージ
    final String message;
    final String? subMessage;
    if (appState.allStamped) {
      message = 'すべての地点をめぐりました！';
      subMessage = '宿場印と引き換えられます。';
    } else if (onQuiz == null) {
      message = '最後の地点です。おつかれさまでした！';
      subMessage = null;
    } else {
      message = '枚方宿の歴史をひとつ、たのしみました！';
      subMessage = 'つぎの地点もがんばりましょう！';
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _RaysPainter()))),
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ConfettiPainter()))),
          SafeArea(
            child: Column(
              children: [
                // 右上の設定ボタン（root_screen.dart で重ねている）の分の空き
                const SizedBox(height: 60),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      Text('スタンプ獲得！',
                          textAlign: TextAlign.center,
                          style: minchoStyle.copyWith(fontSize: 32, color: AppColors.shu)),
                      const SizedBox(height: 4),
                      Text('おめでとうございます！',
                          textAlign: TextAlign.center, style: minchoStyle.copyWith(fontSize: 18)),
                      Center(child: StampPress(order: cp.order, size: stampSize)),
                      Center(child: _Ribbon(text: cp.name)),
                      const SizedBox(height: 10),
                      Text(spotName(cp), textAlign: TextAlign.center, style: minchoStyle.copyWith(fontSize: 30)),
                      const SizedBox(height: 6),
                      const _OrnamentDivider(),
                      const SizedBox(height: 14),
                      _MessageCard(message: message, subMessage: subMessage),
                      const SizedBox(height: 20),
                      if (onQuiz != null) ...[
                        BigButton(label: 'クイズに進む', filled: true, onPressed: onQuiz),
                        const SizedBox(height: 10),
                        BigButton(label: 'マップに戻る', onPressed: () => appState.goToTab(4)),
                      ] else ...[
                        BigButton(label: 'マップに戻る', filled: true, onPressed: () => appState.goToTab(4)),
                        const SizedBox(height: 10),
                        BigButton(label: 'スタンプ一覧を見る', onPressed: () => appState.goToTab(0)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 「第2地点」の赤いリボン。両端の少し下に、切り込みの入った濃い色の端を付ける
class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RibbonPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
        child: Text(text, style: minchoStyle.copyWith(fontSize: 18, color: Colors.white, letterSpacing: 2)),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tail = 26.0; // 端の長さ
    const drop = 6.0; // 端を下げる量
    const notch = 8.0; // 切り込みの深さ
    final h = size.height;
    final w = size.width;
    final dark = Paint()..color = const Color(0xFF8E2F22);
    final main = Paint()..color = AppColors.shu;

    // 左の端
    canvas.drawPath(
      Path()
        ..moveTo(tail - 4, drop)
        ..lineTo(-tail + 18, drop)
        ..lineTo(-tail + 18 + notch, drop + h / 2)
        ..lineTo(-tail + 18, drop + h)
        ..lineTo(tail - 4, drop + h)
        ..close(),
      dark,
    );
    // 右の端
    canvas.drawPath(
      Path()
        ..moveTo(w - tail + 4, drop)
        ..lineTo(w + tail - 18, drop)
        ..lineTo(w + tail - 18 - notch, drop + h / 2)
        ..lineTo(w + tail - 18, drop + h)
        ..lineTo(w - tail + 4, drop + h)
        ..close(),
      dark,
    );
    // 真ん中の帯
    canvas.drawRect(Rect.fromLTWH(14, 0, w - 28, h), main);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 名前の下の飾りの区切り線
class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.6)));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 8, height: 8, color: AppColors.gold),
          ),
        ),
        line,
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.subMessage});

  final String message;
  final String? subMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, color: AppColors.inkSoft, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (subMessage case final sub?) ...[
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// スタンプの後ろから広がる放射状の光
class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // スタンプのあたり（上から3分の1くらい）を中心にする
    final center = Offset(size.width / 2, size.height * 0.36);
    final radius = size.longestSide;
    const count = 28;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < count; i += 2) {
      final a1 = 2 * math.pi * i / count;
      final a2 = 2 * math.pi * (i + 1) / count;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + radius * math.cos(a1), center.dy + radius * math.sin(a1))
          ..lineTo(center.dx + radius * math.cos(a2), center.dy + radius * math.sin(a2))
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 金色の紙吹雪。毎回同じ場所に出るよう、位置は決めておく（画面の幅・高さに対する割合）
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  static const _pieces = [
    (0.08, 0.14, 7.0), (0.22, 0.09, 5.0), (0.86, 0.12, 8.0), (0.72, 0.20, 5.0),
    (0.12, 0.30, 6.0), (0.92, 0.34, 6.0), (0.05, 0.46, 5.0), (0.95, 0.50, 7.0),
    (0.18, 0.58, 4.0), (0.84, 0.62, 5.0), (0.30, 0.18, 4.0), (0.64, 0.08, 6.0),
    (0.10, 0.72, 5.0), (0.90, 0.78, 4.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold.withValues(alpha: 0.75);
    for (final (x, y, s) in _pieces) {
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
