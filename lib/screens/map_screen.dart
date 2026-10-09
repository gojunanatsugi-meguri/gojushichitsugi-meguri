import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_state.dart';
import '../theme.dart';

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

  LatLng? _currentPosition;
  bool _zoomLocked = false;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    if (_gettingLocation) {
      return;
    }

    _gettingLocation = true;

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('位置情報サービスをONにしてください'),
            ),
          );
        }
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('位置情報の使用が許可されませんでした'),
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '位置情報が完全に拒否されています．端末の設定から許可してください',
              ),
            ),
          );
        }
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

      _mapController.move(
        currentLocation,
        16.0,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('現在地を取得できませんでした：$e'),
          ),
        );
      }
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final double mapHeight =
        MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '地図',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: _initialCenter,
                        initialZoom: 14.0,
                        minZoom: 5.0,
                        maxZoom: 19.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.gojushichitsugi_meguri',
                        ),

                        if (_currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition!,
                                width: 40,
                                height: 40,
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
                      ],
                    ),

                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: [
                          Material(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(8),
                            elevation: 3,
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                size: 30,
                              ),
                              tooltip: 'ズームイン',
                              onPressed: _zoomIn,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Material(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(8),
                            elevation: 3,
                            child: IconButton(
                              icon: const Icon(
                                Icons.remove,
                                size: 30,
                              ),
                              tooltip: 'ズームアウト',
                              onPressed: _zoomOut,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Material(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(8),
                            elevation: 3,
                            child: IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                size: 26,
                              ),
                              tooltip: '現在地',
                              onPressed: _getCurrentLocation,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.line,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'スポット一覧',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...spots.map((spot) {
                    final got =
                        appState.stampedSpotIds.contains(spot.id);

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Text(
                            got ? '●' : '○',
                            style: TextStyle(
                              fontSize: 20,
                              color: got
                                  ? AppColors.gold
                                  : AppColors.line,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            '${spot.name}（${spot.category}）',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}