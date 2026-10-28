// 起動時に Firestore から地点・店データを読み込む。
// cloud_firestore を使うので、Flutter に依存しない meguri_data.dart とはファイルを分けている
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'meguri_data.dart';

// どちらのデータを使っているか（動作確認用）
String meguriDataSource = '直書き';

/// main() で Firebase.initializeApp の後に一度だけ呼ぶ。
/// 読めなかったら何もしない ＝ 直書きデータのまま動く
Future<void> loadMeguriData() async {
  try {
    final db = FirebaseFirestore.instance;
    // 2つを同時に読む。圏外で待たされ続けないよう5秒で打ち切る
    final results = await Future.wait([
      db.collection('checkpoints').get(),
      db.collection('shops').get(),
    ]).timeout(const Duration(seconds: 5));

    final cps = results[0].docs.map((d) => Checkpoint.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final sps = results[1].docs.map((d) => Shop.fromMap(d.id, d.data())).toList();

    // 空のとき（初期データ投入前・初回起動で圏外など）は差し替えない
    if (cps.isEmpty || sps.isEmpty) {
      debugPrint('Firestore の地点・店データが空。直書きデータを使います');
      return;
    }

    // 片方だけ新しくなると食い違うので、両方そろってから差し替える
    checkpoints = cps;
    shops = sps;
    meguriDataSource = results[1].metadata.isFromCache ? 'Firestore（端末のキャッシュ）' : 'Firestore';
    debugPrint('地点・店データ: $meguriDataSource から ${cps.length} 地点・${sps.length} 店');
  } catch (e) {
    // 通信失敗・時間切れ・項目の書き間違いなど。アプリは止めずに直書きデータで続ける
    debugPrint('地点・店データの読み込みに失敗。直書きデータを使います: $e');
  }
}
