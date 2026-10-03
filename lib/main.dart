import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_state.dart';
import 'screens/root_screen.dart';
import 'services/progress_store.dart';
import 'theme.dart';

Future<void> main() async {
  // runApp より前にプラグイン（SharedPreferences）を使うために必要
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(GojushichitsugiApp(store: ProgressStore(prefs)));
}

class GojushichitsugiApp extends StatelessWidget {
  // テストでは store を渡さず、保存しない状態で起動する
  const GojushichitsugiApp({super.key, this.store});

  final ProgressStore? store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(store: store),
      child: MaterialApp(
        title: '五十七次めぐり',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const RootScreen(),
      ),
    );
  }
}
