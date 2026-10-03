import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/location_check.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'test_qr_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool cameraOn = false;
  String errorMsg = '';
  // onDetect は1回の読み取りで何度も呼ばれるので、処理中は次を受け付けない
  bool busy = false;
  // 位置確認で「近い」と判定できなかった店。null でなければ確認待ちの画面を出す
  Shop? pendingShop;
  // ライトの切り替えのために自分でコントローラーを持つ。
  // MobileScanner が画面から外れるとカメラは止まり、再び表示すると動き出す
  final scanner = MobileScannerController();

  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }

  void _startCamera() {
    setState(() {
      cameraOn = true;
      errorMsg = '';
    });
  }

  void _stopCamera() {
    setState(() => cameraOn = false);
  }

  Future<void> _handleDecoded(String value) async {
    if (busy) return;
    setState(() {
      busy = true;
      cameraOn = false;
      errorMsg = '';
    });

    final shop = findShopByQrValue(value);
    if (shop == null) {
      setState(() {
        busy = false;
        errorMsg = value.startsWith(qrPrefix)
            ? 'このQRコードは使えません。お店に貼ってあるQRコードをもう一度読み取ってください。'
            : '五十七次めぐりのQRコードではないようです。';
      });
      return;
    }

    if (kRequireLocationCheck) {
      await _checkLocationThenCheckIn(shop);
    } else {
      _completeCheckIn(shop);
    }
  }

  Future<void> _checkLocationThenCheckIn(Shop shop) async {
    setState(() {
      busy = true;
      pendingShop = null;
    });
    final result = await checkNearShop(shop);
    // await の間に画面が破棄されていたら setState できないので確認する
    if (!mounted) return;
    if (result == LocationCheckResult.near) {
      _completeCheckIn(shop);
    } else {
      setState(() {
        busy = false;
        pendingShop = shop;
      });
    }
  }

  void _completeCheckIn(Shop shop) {
    final appState = context.read<AppState>();
    appState.checkIn(shop);
    setState(() {
      busy = false;
      pendingShop = null;
    });
    appState.goToTab(2);
  }

  Future<void> _askStaff(Shop shop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _StaffPinDialog(shop: shop),
    );
    if (ok == true && mounted) _completeCheckIn(shop);
  }

  @override
  Widget build(BuildContext context) {
    // 下タブで別の画面にいる間は IndexedStack で隠れているだけなので、
    // カメラを描画しない（＝止める）ようにする
    final visible = context.select<AppState, bool>((s) => s.currentTabIndex == 1);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('QR読取', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('お店に貼ってあるQRコードを読み取ると、スタンプがもらえます。',
                style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
            const SizedBox(height: 20),
            if (pendingShop != null)
              _LocationFallbackCard(
                shop: pendingShop!,
                onRetry: () => _checkLocationThenCheckIn(pendingShop!),
                onAskStaff: () => _askStaff(pendingShop!),
                onCancel: () => setState(() => pendingShop = null),
              )
            else if (busy)
              const AppCard(
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('お店の近くにいるか確かめています…', style: TextStyle(fontSize: 20)),
                    SizedBox(height: 8),
                  ],
                ),
              )
            else
              AppCard(
                child: Column(
                  children: [
                    if (cameraOn && visible)
                      SizedBox(
                        height: 320,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: MobileScanner(
                            controller: scanner,
                            errorBuilder: (context, error) => _CameraError(error: error),
                            onDetect: (capture) {
                              final raw = capture.barcodes.firstOrNull?.rawValue;
                              if (raw != null) _handleDecoded(raw);
                            },
                          ),
                        ),
                      ),
                    if (cameraOn && visible) _TorchButton(scanner: scanner),
                    if (cameraOn) const SizedBox(height: 12),
                    if (!cameraOn) ...[
                      BigButton(label: 'カメラでQRを読み取る', onPressed: _startCamera, filled: true),
                      if (errorMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(errorMsg, style: const TextStyle(color: Color(0xFFB23A2E), fontSize: 18)),
                        ),
                    ] else
                      BigButton(label: 'カメラを止める', onPressed: _stopCamera),
                  ],
                ),
              ),

            // 手動で店を選ぶ操作は開発中（デバッグ実行）だけ表示する。
            // リリース版に残すと、現地に行かずにスタンプが取れてしまうため
            if (kDebugMode && pendingShop == null && !busy) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('開発用：お店を選んで読み取ったことにする', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 10),
                    ...shops.map((shop) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              // 本物のQRと同じ経路を通す（位置確認も含めて試せるように）
                              onPressed: () => _handleDecoded(shop.qrValue),
                              child: Text('${shop.name}（${shop.category}）のQRを読む'),
                            ),
                          ),
                        )),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TestQrScreen()),
                      ),
                      child: const Text('テスト用QRコードを表示する'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AppState>().resetProgress();
                        setState(() => errorMsg = '');
                      },
                      child: const Text('スタンプ・クイズの進み具合をリセットする'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// カメラが使えないときの案内。英語のエラーをそのまま出さず、次に何をすればよいかを伝える
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'カメラの使用が許可されていません。\nスマートフォンの「設定」から、このアプリのカメラをオンにしてください。',
      MobileScannerErrorCode.unsupported => 'この端末ではカメラを使えません。',
      _ => 'カメラを起動できませんでした。\n「カメラを止める」を押して、もう一度お試しください。',
    };
    return ColoredBox(
      color: AppColors.indigoSoft,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: AppColors.ink)),
        ),
      ),
    );
  }
}

// 店内が暗くて読み取れないとき用。ライトのない端末では表示しない
class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.scanner});

  final MobileScannerController scanner;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: scanner,
      builder: (context, state, _) {
        if (!state.isRunning || state.torchState == TorchState.unavailable) return const SizedBox.shrink();
        final on = state.torchState == TorchState.on;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: BigButton(label: on ? 'ライトを消す' : '暗いときはライトをつける', onPressed: scanner.toggleTorch),
        );
      },
    );
  }
}

// 位置確認で近いと判定できなかったとき。ここで止めてしまうと、
// GPSがずれただけの人がスタンプを取れずに帰ってしまうので、必ず先へ進める道を用意する
class _LocationFallbackCard extends StatelessWidget {
  const _LocationFallbackCard({
    required this.shop,
    required this.onRetry,
    required this.onAskStaff,
    required this.onCancel,
  });

  final Shop shop;
  final VoidCallback onRetry;
  final VoidCallback onAskStaff;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('「${shop.name}」の近くにいることを確かめられませんでした。',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('お店の中では位置がずれることがあります。お店の方に画面を見せると、スタンプを受け取れます。',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          BigButton(label: 'お店の方に確認してもらう', onPressed: onAskStaff, filled: true),
          const SizedBox(height: 10),
          BigButton(label: 'もう一度確かめる', onPressed: onRetry),
          const SizedBox(height: 10),
          BigButton(label: '戻る', onPressed: onCancel),
        ],
      ),
    );
  }
}

class _StaffPinDialog extends StatefulWidget {
  const _StaffPinDialog({required this.shop});

  final Shop shop;

  @override
  State<_StaffPinDialog> createState() => _StaffPinDialogState();
}

class _StaffPinDialogState extends State<_StaffPinDialog> {
  final controller = TextEditingController();
  String error = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (controller.text.trim() == widget.shop.staffPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => error = '番号が違います。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('お店の方へ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.shop.name}の確認番号を入力してください。', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            autofocus: true,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            onSubmitted: (_) => _submit(),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error, style: const TextStyle(color: Color(0xFFB23A2E), fontSize: 16)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('戻る')),
        FilledButton(onPressed: _submit, child: const Text('確認する')),
      ],
    );
  }
}
