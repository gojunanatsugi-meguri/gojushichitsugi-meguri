import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_state.dart';
import '../models/route_guide.dart';
import '../theme.dart';
import '../widgets/common.dart';

// ホーム画面。地図を大きく出し、下に「次の目的地」と QR 読取のボタンを置く。
// 地図が読めない方でも、下のカードの文字だけで次にすることが分かるようにしている
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

  void _showCheckpoint(Checkpoint cp) {
    final pos = checkpointPosition(cp.id);
    if (pos != null) _mapController.move(pos, 17.0);
  }

  void _showSpotList(AppState appState, Checkpoint? target) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Text(
              '地点の一覧',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...checkpoints.map((cp) {
              final got = appState.stampedCheckpointIds.contains(cp.id);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _CheckpointBadge(order: cp.order, stamped: got, isTarget: cp.id == target?.id),
                title: Text(cp.name, style: const TextStyle(fontSize: 18)),
                subtitle: Text(shopsAt(cp.id).map((s) => '${s.name}（${s.category}）').join('、')),
                trailing: got ? const Text('スタンプ済み', style: TextStyle(color: AppColors.gold)) : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showCheckpoint(cp);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 現在地が分かって枚方宿の近くにいれば現在地から、そうでなければ最後に行った地点から測る。
  // どちらも分からない（まだ1か所も行っていない・位置情報がオフ）ときは null
  WalkEstimate? _estimateTo(AppState appState, Checkpoint target) {
    final to = checkpointPosition(target.id);
    if (to == null) return null;
    final here = _currentPosition;
    if (here != null && _isNearRoute(here)) return estimateWalk(here, to);
    final last = appState.lastScannedCheckpointId;
    final from = last == null ? null : checkpointPosition(last);
    return from == null ? null : estimateWalk(from, to);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final stamped = appState.stampedCheckpointIds;
    final target = nextTarget(stamped);
    final positions = _checkpointPositions;

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
                        for (final cp in checkpoints)
                          if (checkpointPosition(cp.id) case final pos?)
                            Marker(
                              point: pos,
                              width: 48,
                              height: 48,
                              child: GestureDetector(
                                onTap: () => _showCheckpoint(cp),
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

                // 上：宿場名と進み具合
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _StatusChip(
                        stampedCount: stamped.length,
                        total: checkpoints.length,
                        steps: appState.stepCount,
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

                // 左下：地点の一覧
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _showSpotList(appState, target),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list, color: AppColors.indigo),
                            SizedBox(width: 6),
                            Text('地点の一覧', style: TextStyle(fontSize: 16, color: AppColors.indigo)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _NextPanel(
            appState: appState,
            target: target,
            estimate: target == null ? null : _estimateTo(appState, target),
            onShowTarget: target == null ? null : () => _showCheckpoint(target),
          ),
        ],
      ),
    );
  }
}

// 地図の上の地点の印。行った地点は金色のチェック、次の目的地は朱色で大きく出す
class _CheckpointBadge extends StatelessWidget {
  const _CheckpointBadge({required this.order, required this.stamped, required this.isTarget});

  final int order;
  final bool stamped;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    final size = isTarget ? 44.0 : 36.0;
    final fill = stamped ? AppColors.gold : (isTarget ? AppColors.shu : Colors.white);
    final fg = stamped || isTarget ? Colors.white : AppColors.indigo;
    // 外側の大きさを固定する（一覧の行の左に置いたとき、横いっぱいに広がらないように）
    return SizedBox.square(
      dimension: 48,
      child: Center(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: stamped || isTarget ? Colors.white : AppColors.indigo, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: stamped
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text('$order', style: TextStyle(color: fg, fontSize: isTarget ? 20 : 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
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

// 下のカード。次の目的地・そこまでの目安・お知らせ・QR 読取のボタン
class _NextPanel extends StatelessWidget {
  const _NextPanel({
    required this.appState,
    required this.target,
    required this.estimate,
    required this.onShowTarget,
  });

  final AppState appState;
  final Checkpoint? target;
  final WalkEstimate? estimate;
  final VoidCallback? onShowTarget;

  @override
  Widget build(BuildContext context) {
    final target = this.target;

    // 最後に読んだ地点のクイズにまだ答えていなければ知らせる（クイズ画面はその地点の問題を出すため）
    final lastId = appState.lastScannedCheckpointId;
    final quizPending = lastId != null &&
        findCheckpointById(lastId)?.quiz != null &&
        !appState.quizResults.containsKey(lastId);
    final usableCoupons = appState.obtainedCoupons.where((s) => !appState.isCouponUsed(s.id)).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (target == null) ...[
            const Text('枚方宿の地点を、すべてめぐりました！',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('スタンプ帳で、集めたスタンプを見てみましょう。', style: TextStyle(color: AppColors.inkSoft)),
          ] else
            InkWell(
              onTap: onShowTarget,
              child: Row(
                children: [
                  _CheckpointBadge(order: target.order, stamped: false, isTarget: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('次の目的地', style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                        Text(target.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Text(shopsAt(target.id).map((s) => '${s.name}（${s.category}）').join('、'),
                            style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
                        if (estimate case final e?)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('あと約${_withComma(e.steps)}歩（約${e.minutes}分）',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.shu)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (quizPending)
            _Notice(icon: Icons.help_outline, text: 'クイズにまだ答えていません', onTap: () => appState.goToTab(2)),
          if (usableCoupons > 0)
            _Notice(
              icon: Icons.confirmation_number,
              text: '使えるクーポンが$usableCoupons枚あります',
              onTap: () => appState.goToTab(3),
            ),

          const SizedBox(height: 12),
          target == null
              ? BigButton(label: 'スタンプ帳を見る', filled: true, onPressed: () => appState.goToTab(0))
              : BigButton(label: 'QRを読み取る', filled: true, onPressed: () => appState.goToTab(1)),
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
