import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_state.dart';
import '../theme.dart';

// 開発用：本物の店舗QRができるまで、別の端末でこの画面を開いてカメラで読み取って試す。
// QR読取画面の開発用メニュー（デバッグ実行のときだけ表示）から開く
class TestQrScreen extends StatelessWidget {
  const TestQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('テスト用QRコード')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final shop in shops) ...[
            Text('${shop.name}（${shop.category}）', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('確認番号: ${shop.staffPin}', style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(data: shop.qrValue, size: 220),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
