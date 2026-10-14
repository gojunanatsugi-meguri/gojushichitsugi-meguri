import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_state.dart';
import 'screens/start_screen.dart';
import 'services/health_service.dart';
import 'services/progress_store.dart';
import 'theme.dart';
import 'services/firebase_setup.dart';

Future<void> main() async {
  // runApp より前にプラグイン（SharedPreferences）を使うために必要
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(GojushichitsugiApp(
    store: await createProgressStore(prefs),
    readDistanceKm: HealthService.getTodayDistanceKm,
  ));
}

class GojushichitsugiApp extends StatefulWidget {
  // テストでは store・readDistanceKm を渡さず、保存も歩数の読み取りもしない状態で起動する
  const GojushichitsugiApp({super.key, this.store, this.readDistanceKm});

  final ProgressStore? store;
  final Future<double> Function()? readDistanceKm;

  @override
  State<GojushichitsugiApp> createState() => _GojushichitsugiAppState();
}

class _GojushichitsugiAppState extends State<GojushichitsugiApp> {
  late final AppState _appState = AppState(store: widget.store, readDistanceKm: widget.readDistanceKm);
  // 散歩から戻ってアプリを開き直したときにも、歩数を読み直す
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _appState.refreshSteps);
    _appState.refreshSteps();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp(
        title: '五十七次めぐり',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const StartScreen(),
      ),
    );
  }
}
