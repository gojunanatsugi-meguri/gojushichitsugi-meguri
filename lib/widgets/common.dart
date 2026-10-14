import 'package:flutter/material.dart';
import '../theme.dart';

// 白地・枠線付きのカード。各画面で同じ見た目にそろえるための共通部品
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

// 画面幅いっぱいの大きなボタン（65歳以上の利用者でも押しやすいように）
class BigButton extends StatelessWidget {
  const BigButton({super.key, required this.label, required this.onPressed, this.filled = false});

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(label, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
    );
    return SizedBox(
      width: double.infinity,
      child: filled ? FilledButton(onPressed: onPressed, child: text) : OutlinedButton(onPressed: onPressed, child: text),
    );
  }
}
