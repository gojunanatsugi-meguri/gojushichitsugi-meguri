import 'package:flutter/material.dart';
import '../theme.dart';

// スタンプの見た目と、押されるときの動き。スタンプ帳とクイズ画面（獲得したとき）で使う

const _kanjiNumbers = ['壱', '弐', '参', '肆', '伍', '陸', '漆', '捌', '玖', '拾'];

String _kanjiNumber(int n) => n >= 1 && n <= _kanjiNumbers.length ? _kanjiNumbers[n - 1] : '$n';

// 押したスタンプの見た目。朱色の二重丸に、地点の番号（漢数字）を入れる。
// 地点ごとに少しずつ傾けて、手で押したように見せる
class StampMark extends StatelessWidget {
  const StampMark({super.key, required this.order, required this.size});

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

// 画面に出たときに1回だけ、スタンプが「ポン」と押される動きをする。
// 大きく薄い状態から落ちてきて少し沈み、元の大きさに戻る。押した瞬間に朱色の輪が広がって消える。
// 端末の設定で動きを減らしている人には、動かさずに押した状態で出す
class StampPress extends StatefulWidget {
  const StampPress({super.key, required this.order, this.size = 140});

  final int order;
  final double size;

  @override
  State<StampPress> createState() => _StampPressState();
}

class _StampPressState extends State<StampPress> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  // 0〜0.5：落ちてくる、0.5〜0.65：少し沈む、0.65〜0.8：戻る
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 2.2, end: 0.9).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.04).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
  ]).animate(_controller);

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.4, curve: Curves.easeOut),
  );

  // 押した瞬間（0.5）から広がる輪
  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox.square(
      dimension: size * 1.4,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            if (_ring.value > 0 && _ring.value < 1)
              Container(
                width: size * (1 + 0.4 * _ring.value),
                height: size * (1 + 0.4 * _ring.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.shu.withValues(alpha: 0.5 * (1 - _ring.value)),
                    width: 4,
                  ),
                ),
              ),
            Opacity(
              opacity: _opacity.value,
              child: Transform.scale(scale: _scale.value, child: child),
            ),
          ],
        ),
        child: StampMark(order: widget.order, size: size),
      ),
    );
  }
}
