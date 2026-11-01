import 'dart:math' as math;

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

// 画面を開くとすぐカメラが動き、真ん中の枠にQRを写すだけで読み取れる。
// 読み取れないときの工夫（ライトなど）は「うまく読み取れない場合」にまとめている
class _ScanScreenState extends State<ScanScreen> {
  String errorMsg = '';
  // onDetect は1回の読み取りで何度も呼ばれるので、処理中は次を受け付けない
  bool busy = false;
  // 使えないQRを写し続けているあいだ、同じ案内を何度も出し直さないため
  String? _lastBadValue;
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

  Future<void> _handleDecoded(String value) async {
    if (busy || value == _lastBadValue) return;
    setState(() {
      busy = true;
      errorMsg = '';
    });

    final shop = findShopByQrValue(value);
    if (shop == null) {
      setState(() {
        busy = false;
        _lastBadValue = value;
        errorMsg = value.startsWith(qrPrefix)
            ? 'このQRコードは使えません。地点に貼ってあるQRコードを写してください。'
            : '五十七次めぐりのQRコードではないようです。';
      });
      return;
    }
    _lastBadValue = null;

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

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HelpSheet(scanner: scanner),
    );
  }

  // 手動で店を選ぶ操作は開発中（デバッグ実行）だけ出す。
  // リリース版に残すと、現地に行かずにスタンプが取れてしまうため
  void _showDevMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      builder: (sheetContext) {
        void run(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                          onPressed: () => run(() => _handleDecoded(shop.qrValue)),
                          child: Text('${shop.name}（${shop.category}）のQRを読む'),
                        ),
                      ),
                    )),
                TextButton(
                  onPressed: () => run(() => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TestQrScreen()),
                      )),
                  child: const Text('テスト用QRコードを表示する'),
                ),
                TextButton(
                  onPressed: () => run(() {
                    context.read<AppState>().resetProgress();
                    setState(() => errorMsg = '');
                  }),
                  child: const Text('スタンプ・クイズの進み具合をリセットする'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 下タブで別の画面にいる間は IndexedStack で隠れているだけなので、
    // カメラを描画しない（＝止める）ようにする
    final visible = context.select<AppState, bool>((s) => s.currentTabIndex == 1);

    final Widget middle;
    if (pendingShop != null) {
      middle = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _LocationFallbackCard(
          shop: pendingShop!,
          onRetry: () => _checkLocationThenCheckIn(pendingShop!),
          onAskStaff: () => _askStaff(pendingShop!),
          onCancel: () => setState(() => pendingShop = null),
        ),
      );
    } else {
      middle = ColoredBox(
        color: Colors.black,
        child: busy
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('お店の近くにいるか確かめています…', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (visible)
                    MobileScanner(
                      controller: scanner,
                      errorBuilder: (context, error) => _CameraError(error: error),
                      onDetect: (capture) {
                        final raw = capture.barcodes.firstOrNull?.rawValue;
                        if (raw != null) _handleDecoded(raw);
                      },
                    ),
                  const IgnorePointer(child: CustomPaint(painter: _ScanFramePainter())),
                ],
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // 右上は設定ボタン（root_screen.dart で重ねている）の場所なので空けておく
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 72, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('QR読取', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _GuideBox(errorMsg: errorMsg),
            ),
            Expanded(child: middle),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 12),
              child: Column(
                children: [
                  _HelpButton(onPressed: _showHelp),
                  if (kDebugMode) TextButton(onPressed: _showDevMenu, child: const Text('開発用メニュー')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 上の「地点のQRコードを写してください」の枠（中は背景と同じ色）。使えないQRを写したときは、その下に赤字で理由を出す
class _GuideBox extends StatelessWidget {
  const _GuideBox({required this.errorMsg});

  final String errorMsg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: AppColors.shu, size: 28),
              SizedBox(width: 10),
              Flexible(
                child: Text('地点のQRコードを写してください',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ],
          ),
          if (errorMsg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB23A2E), fontSize: 16)),
          ],
        ],
      ),
    );
  }
}

// カメラの映像の上に重ねる、四すみのかぎ型の枠
class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height) * 0.62;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    const arm = 34.0; // かぎの長さ
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    for (final (corner, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner.translate(arm * dx, 0), paint);
      canvas.drawLine(corner, corner.translate(0, arm * dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 下の「うまく読み取れない場合」のボタン
class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.help, color: AppColors.indigoDeep, size: 28),
        label: const Text('うまく読み取れない場合', style: TextStyle(fontSize: 18, color: AppColors.ink)),
      ),
    );
  }
}

// 「うまく読み取れない場合」を押すと出る説明。暗いときのライトもここに置く
class _HelpSheet extends StatelessWidget {
  const _HelpSheet({required this.scanner});

  final MobileScannerController scanner;

  @override
  Widget build(BuildContext context) {
    const tips = [
      'QRコード全体が、白い枠の中に入るように写してください。',
      'スマートフォンを近づけすぎず、少し離して（15〜30cmほど）写してください。',
      '光が反射するときは、少し斜めから写してください。',
      'それでも読めないときは、近くのお店の方や係の人に声をかけてください。',
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('うまく読み取れない場合', style: minchoStyle.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle, color: AppColors.indigo, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tip, style: const TextStyle(fontSize: 17, color: AppColors.ink))),
                  ],
                ),
              ),
            _TorchButton(scanner: scanner),
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
      _ => 'カメラを起動できませんでした。\nほかのタブを開いてから、もう一度この画面に戻ってください。',
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

// 店内が暗くて読み取れないとき用。カメラが動いていないときと、ライトのない端末では出さない
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
          padding: const EdgeInsets.only(top: 8),
          child: BigButton(label: on ? 'ライトを消す' : '暗いときはライトをつける', onPressed: scanner.toggleTorch, filled: !on),
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
