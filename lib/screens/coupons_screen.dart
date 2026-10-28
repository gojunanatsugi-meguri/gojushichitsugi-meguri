import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  // 一度使うと元に戻せないので、押し間違いを防ぐために確認をはさむ
  Future<void> _confirmUse(BuildContext context, Shop shop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('「${shop.name}」のクーポンを使いますか？'),
        content: const Text('お店の方の前で押してください。\n使ったクーポンは元に戻せません。', style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('戻る', style: TextStyle(fontSize: 18))),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('使う', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<AppState>().useCoupon(shop.id);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('獲得クーポン', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('お店で「このクーポンを使う」を押して、この画面をお店の方に見せてください。',
                style: TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 20),

            if (appState.obtainedCoupons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text('まだクーポンがありません。QRを読み取ってクイズに正解すると、ここに増えていきます。',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkSoft)),
              )
            else
              ...appState.obtainedCoupons.map((coupon) {
                final usedAt = appState.couponUsedAt[coupon.id];
                return _CouponCard(
                  shop: coupon,
                  usedAt: usedAt,
                  onUse: () => _confirmUse(context, coupon),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.shop, required this.usedAt, required this.onUse});

  final Shop shop;
  final DateTime? usedAt;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final used = usedAt != null;

    // 使用済みは色を薄くして、まだ使えるクーポンと見分けやすくする
    return Opacity(
      opacity: used ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: used ? AppColors.line : AppColors.gold, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(shop.coupon,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (used)
              // 店員さんが一目で「いつ使ったか」を確かめられるように日時も出す
              Text('使用済み（${_formatDateTime(usedAt!)}）',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.inkSoft))
            else
              BigButton(label: 'このクーポンを使う', filled: true, onPressed: onUse),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.month}月${t.day}日 ${two(t.hour)}:${two(t.minute)}';
}
