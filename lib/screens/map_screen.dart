import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';

import '../models/app_state.dart';
import '../models/route_guide.dart';
import '../theme.dart';
import '../widgets/common.dart';

// ホーム画面。地図を大きく出し、地点を押したときだけ、下にその地点のカード
// （現在地からの歩数の目安と QR 読取のボタン）を出す。閉じると、その分地図が広くなる。
// 左上の「地点の一覧」は、押すたびに開いたり閉じたりする
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  static const LatLng _initialCenter = LatLng(
    34.8143,
    135.6507,
  );

  // 起動時に現在地へ地図を動かすのは、枚方宿の近くにいるときだけ（遠くにいると地点が見えなくなるため）
  static const double _nearbyMeters = 3000;

  LatLng? _currentPosition;
  // 歩いている間も現在地を追いかける（歩数の目安を、いる場所に合わせて変えるため）
  StreamSubscription<Position>? _positionSub;
  // 地図や一覧で選んだ地点。null のときは下のカードを出さない
  String? _selectedId;
  // 「地点の一覧」を開いているか
  bool _listOpen = false;
  bool _zoomLocked = false;
  bool _gettingLocation = false;

  List<LatLng> get _checkpointPositions =>
      checkpoints.map((c) => checkpointPosition(c.id)).whereType<LatLng>().toList();

  LatLng get _routeCenter {
    final list = _checkpointPositions;
    if (list.isEmpty) return _initialCenter;
    return LatLng(
      list.map((p) => p.latitude).reduce((a, b) => a + b) / list.length,
      list.map((p) => p.longitude).reduce((a, b) => a + b) / list.length,
    );
  }

  bool _isNearRoute(LatLng p) =>
      const Distance().as(LengthUnit.Meter, p, _routeCenter) <= _nearbyMeters;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation(quiet: true);
    });
  }

  // quiet: 起動時の自動取得。ホーム画面は毎回開くので、失敗してもメッセージは出さない
  Future<void> _getCurrentLocation({bool quiet = false}) async {
    if (_gettingLocation) {
      return;
    }

    _gettingLocation = true;

    void showMessage(String text) {
      if (!quiet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text)),
        );
      }
    }

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        showMessage('位置情報サービスをONにしてください');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        showMessage('位置情報の使用が許可されませんでした');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        showMessage('位置情報が完全に拒否されています．端末の設定から許可してください');
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = currentLocation;
      });
      _watchPosition();

      if (!quiet || _isNearRoute(currentLocation)) {
        _mapController.move(
          currentLocation,
          16.0,
        );
      }
    } catch (e) {
      showMessage('現在地を取得できませんでした：$e');
    } finally {
      _gettingLocation = false;
    }
  }

  Future<void> _zoom(double amount) async {
    if (_zoomLocked) {
      return;
    }

    _zoomLocked = true;

    final camera = _mapController.camera;

    final double newZoom =
        (camera.zoom + amount).clamp(5.0, 19.0).toDouble();

    _mapController.move(
      camera.center,
      newZoom,
    );

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    _zoomLocked = false;
  }

  void _zoomIn() {
    _zoom(1.0);
  }

  void _zoomOut() {
    _zoom(-1.0);
  }

  // 位置情報の許可が取れたあとに呼ぶ。10m 動くごとに現在地を更新する
  void _watchPosition() {
    if (_positionSub != null) return;
    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (p) {
          if (mounted) setState(() => _currentPosition = LatLng(p.latitude, p.longitude));
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _select(Checkpoint cp) {
    setState(() {
      _selectedId = cp.id;
      _listOpen = false;
    });
    final pos = checkpointPosition(cp.id);
    if (pos != null) _mapController.move(pos, _mapController.camera.zoom < 16 ? 16.0 : _mapController.camera.zoom);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final stamped = appState.stampedCheckpointIds;
    final target = nextTarget(stamped);
    final shown = findCheckpointById(_selectedId);
    final positions = _checkpointPositions;

    // 最後に読んだ地点のクイズにまだ答えていなければ知らせる（クイズ画面はその地点の問題を出すため）
    final lastId = appState.lastScannedCheckpointId;
    final quizPending = lastId != null &&
        findCheckpointById(lastId)?.quiz != null &&
        !appState.quizResults.containsKey(lastId);
    final usableCoupons = appState.obtainedCoupons.where((s) => !appState.isCouponUsed(s.id)).length;
    // 左上の一覧の幅。右のズームボタンにかぶらないようにする
    final listWidth = (MediaQuery.of(context).size.width - 24 - 64 - 8).clamp(200.0, 320.0);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: 14.0,
                    initialCameraFit: positions.isEmpty
                        ? null
                        : CameraFit.coordinates(
                            coordinates: positions,
                            padding: const EdgeInsets.fromLTRB(48, 120, 80, 48),
                            maxZoom: 17,
                          ),
                    minZoom: 5.0,
                    maxZoom: 19.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'jp.ac.oit.gojushichitsugiMeguri',
                    ),

                    MarkerLayer(
                      markers: [
                        // 選んでいる地点は、ほかの印に隠れないよう最後に描く
                        for (final cp in [
                          ...checkpoints.where((c) => c.id != shown?.id),
                          ?shown,
                        ])
                          if (checkpointPosition(cp.id) case final pos?)
                            if (cp.id == shown?.id)
                              Marker(
                                point: pos,
                                width: _SelectedMarker.width,
                                height: _SelectedMarker.height,
                                child: GestureDetector(
                                  onTap: () => _select(cp),
                                  child: _SelectedMarker(
                                    name: spotName(cp),
                                    badge: _CheckpointBadge(
                                      order: cp.order,
                                      stamped: stamped.contains(cp.id),
                                      isTarget: cp.id == target?.id,
                                      selected: true,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Marker(
                                point: pos,
                                width: _CheckpointBadge.box,
                                height: _CheckpointBadge.box,
                                child: GestureDetector(
                                  onTap: () => _select(cp),
                                  child: _CheckpointBadge(
                                    order: cp.order,
                                    stamped: stamped.contains(cp.id),
                                    isTarget: cp.id == target?.id,
                                  ),
                                ),
                              ),

                        if (_currentPosition != null)
                          Marker(
                            point: _currentPosition!,
                            width: 28,
                            height: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    // OpenStreetMap の地図を使うときは、出典の表示が必要。
                    // flutter_map の出典表示は小さい画面ではみ出すので、短い文字で出す
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: Colors.white70,
                        child: const Text('© OpenStreetMap', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),

                // 左上：宿場名と進み具合、その下に地点の一覧
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: listWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatusChip(
                              stampedCount: stamped.length,
                              total: checkpoints.length,
                              steps: appState.stepCount,
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: _SpotToggleList(
                                open: _listOpen,
                                onToggle: () => setState(() => _listOpen = !_listOpen),
                                stampedIds: stamped,
                                targetId: target?.id,
                                onSelect: _select,
                                openWidth: listWidth,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 右：ズームと現在地
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _MapButton(icon: Icons.add, tooltip: 'ズームイン', onPressed: _zoomIn),
                          const SizedBox(height: 8),
                          _MapButton(icon: Icons.remove, tooltip: 'ズームアウト', onPressed: _zoomOut),
                          const SizedBox(height: 8),
                          _MapButton(icon: Icons.my_location, tooltip: '現在地', onPressed: _getCurrentLocation),
                        ],
                      ),
                    ),
                  ),
                ),

                // 下：お知らせ（答えていないクイズ・使えるクーポン）
                if (quizPending || usableCoupons > 0)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 24,
                    child: Column(
                      children: [
                        if (quizPending)
                          _Notice(icon: Icons.help_outline, text: 'クイズにまだ答えていません', onTap: () => appState.goToTab(2)),
                        if (usableCoupons > 0)
                          _Notice(
                            icon: Icons.confirmation_number,
                            text: '使えるクーポンが$usableCoupons枚あります',
                            onTap: () => appState.goToTab(3),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 地点を選んでいるときだけ出す
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: shown == null
                ? const SizedBox(width: double.infinity)
                : _SpotPanel(
                    appState: appState,
                    checkpoint: shown,
                    isTarget: shown.id == target?.id,
                    here: _currentPosition,
                    onShow: () => _select(shown),
                    onClose: () => setState(() => _selectedId = null),
                  ),
          ),
        ],
      ),
    );
  }
}

// 地図の上の地点の印。行った地点は金色のチェック、次の目的地は朱色で大きく出す
class _CheckpointBadge extends StatelessWidget {
  const _CheckpointBadge({required this.order, required this.stamped, required this.isTarget, this.selected = false});

  final int order;
  final bool stamped;
  final bool isTarget;
  // 地図で選んでいる地点は、少し大きくする
  final bool selected;

  // 外側の大きさ（地図の印・一覧の行のどちらでも同じ）
  static const box = 52.0;

  @override
  Widget build(BuildContext context) {
    final size = (isTarget ? 44.0 : 36.0) + (selected ? 8 : 0);
    final fill = stamped ? AppColors.gold : (isTarget ? AppColors.shu : Colors.white);
    final fg = stamped || isTarget ? Colors.white : AppColors.indigo;
    // 外側の大きさを固定する（一覧の行の左に置いたとき、横いっぱいに広がらないように）
    return SizedBox.square(
      dimension: box,
      child: Center(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: stamped || isTarget ? Colors.white : AppColors.indigo, width: 3),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: selected ? 8 : 4, offset: Offset(0, selected ? 2 : 0))],
          ),
          child: stamped
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text('$order', style: TextStyle(color: fg, fontSize: isTarget ? 20 : 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// 選んだ地点の印。上にお店の名前の吹き出しを付ける。
// 印の中心が地点の位置に来るよう、吹き出しと同じ高さの空きを下にも取って、上下対称にしている
class _SelectedMarker extends StatelessWidget {
  const _SelectedMarker({required this.name, required this.badge});

  final String name;
  final Widget badge;

  static const _bubbleHeight = 44.0;
  static const width = 200.0;
  static const height = _bubbleHeight * 2 + _CheckpointBadge.box;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _bubbleHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              CustomPaint(size: const Size(14, 7), painter: _BubbleArrow()),
            ],
          ),
        ),
        badge,
        const SizedBox(height: _bubbleHeight),
      ],
    );
  }
}

// 吹き出しの下の小さな三角
class _BubbleArrow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.stampedCount, required this.total, required this.steps});

  final int stampedCount;
  final int total;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('枚方宿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text('スタンプ $stampedCount / $total', style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
            Text('今日 ${_withComma(steps)}歩', style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      child: IconButton(
        icon: Icon(icon, size: 28),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

// 左上の「地点の一覧」。押すたびに、その場で開いたり閉じたりする。
// 閉じているときは小さなボタンの幅で、開いたときだけ openWidth まで広がる
class _SpotToggleList extends StatelessWidget {
  const _SpotToggleList({
    required this.open,
    required this.onToggle,
    required this.stampedIds,
    required this.targetId,
    required this.onSelect,
    required this.openWidth,
  });

  final bool open;
  final VoidCallback onToggle;
  final Set<String> stampedIds;
  final String? targetId;
  final void Function(Checkpoint) onSelect;
  final double openWidth;

  @override
  Widget build(BuildContext context) {
    const title = Text('地点の一覧', style: TextStyle(fontSize: 16, color: AppColors.indigo));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(open ? 12 : 999),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: open ? openWidth : null,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: open ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: open ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      const Icon(Icons.list, color: AppColors.indigo),
                      const SizedBox(width: 6),
                      open ? const Expanded(child: title) : title,
                      const SizedBox(width: 4),
                      Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.indigo),
                    ],
                  ),
                ),
              ),
              if (open)
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 6),
                    children: [
                      for (final cp in checkpoints)
                        InkWell(
                          onTap: () => onSelect(cp),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(6, 2, 12, 2),
                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                            child: Row(
                              children: [
                                _CheckpointBadge(
                                  order: cp.order,
                                  stamped: stampedIds.contains(cp.id),
                                  isTarget: cp.id == targetId,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(spotName(cp),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      Text(
                                        stampedIds.contains(cp.id) ? '${spotCategory(cp)}・スタンプ済み' : spotCategory(cp),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: stampedIds.contains(cp.id) ? AppColors.gold : AppColors.inkSoft),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 下のカード。地図で選んだ地点・現在地からの目安・QR 読取のボタン
class _SpotPanel extends StatelessWidget {
  const _SpotPanel({
    required this.appState,
    required this.checkpoint,
    required this.isTarget,
    required this.here,
    required this.onShow,
    required this.onClose,
  });

  final AppState appState;
  final Checkpoint checkpoint;
  final bool isTarget;
  final LatLng? here;
  final VoidCallback onShow;
  final VoidCallback onClose;

  // 歩数の目安は現在地から測る。現在地が分からないときと、枚方宿から遠いときは歩数を出さない
  Widget? _distanceText(Checkpoint cp) {
    final to = checkpointPosition(cp.id);
    final from = here;
    if (to == null) return null;
    if (from == null) {
      return const Text('右上の ◎ で現在地を出すと、ここまでの歩数が分かります',
          style: TextStyle(fontSize: 14, color: AppColors.inkSoft));
    }
    final meters = const Distance().as(LengthUnit.Meter, from, to);
    if (meters > _MapScreenState._nearbyMeters) {
      return Text('約${(meters / 1000).toStringAsFixed(1)}km（枚方宿から離れています）',
          style: const TextStyle(fontSize: 15, color: AppColors.inkSoft));
    }
    final e = estimateWalk(from, to);
    return Text('あと約${_withComma(e.steps)}歩（約${e.minutes}分）',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.shu));
  }

  @override
  Widget build(BuildContext context) {
    final cp = checkpoint;
    final stamped = appState.stampedCheckpointIds.contains(cp.id);
    final label = isTarget
        ? '次の目的地'
        : stamped
            ? 'スタンプ済みの地点'
            : '選んだ地点';
    final distance = _distanceText(cp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft))),
              IconButton(
                icon: const Icon(Icons.close, size: 26),
                tooltip: '閉じる',
                onPressed: onClose,
              ),
            ],
          ),
          InkWell(
            onTap: onShow,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckpointBadge(order: cp.order, stamped: stamped, isTarget: isTarget),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spotName(cp),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Text('${cp.name}・${spotCategory(cp)}',
                            style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
                        if (distance != null)
                          Padding(padding: const EdgeInsets.only(top: 4), child: distance),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BigButton(label: 'QRを読み取る', filled: true, onPressed: () => appState.goToTab(1)),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: AppColors.indigoSoft,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: AppColors.indigo),
                const SizedBox(width: 8),
                Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.indigoDeep))),
                const Icon(Icons.chevron_right, color: AppColors.indigo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _withComma(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
