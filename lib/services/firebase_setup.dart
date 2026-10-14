import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart'; // flutterfire configure で自動生成されるファイル
import 'cloud_progress_store.dart';
import 'progress_store.dart';

// アプリ起動時に呼ぶ。Firebase を起動して匿名ログインし、保存係を返す。
// ・ログインできたら → 端末＋Firestore に保存する CloudProgressStore
// ・初回起動が圏外などで失敗したら → 端末だけに保存する ProgressStore（今までどおり）
Future<ProgressStore> createProgressStore(SharedPreferences prefs) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final auth = FirebaseAuth.instance;
    // 2回目以降の起動では、前回のログイン状態が残っている
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    if (user != null) return CloudProgressStore(prefs, uid: user.uid);
  } catch (_) {}
  return ProgressStore(prefs);
}
