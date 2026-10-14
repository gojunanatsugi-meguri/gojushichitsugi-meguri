import 'package:cloud_firestore/cloud_firestore.dart';
import 'progress_store.dart';

// 進み具合を「端末」と「Firestore」の両方に保存する。
//
// ・読み込み（load）は今までどおり端末から行う。
//   → 電波の悪い場所でも、すぐに起動・再開できる。
// ・保存（save）は端末に書いたあと、同じ内容を Firestore にも送る。
//   → 参加者数・完歩率などを集計できるようにするため。
//   → 圏外のときは Firestore が端末内にためておき、つながったら自動で送る。
//
// Firestore 上の置き場所： users/{uid}
//   { playerName, progress: { stampedAt, quizResults, couponChoices, ... }, updatedAt }
class CloudProgressStore extends ProgressStore {
  CloudProgressStore(super.prefs, {required this.uid});

  // 匿名ログインで割り当てられたユーザーID
  final String uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  Future<void> save(Map<String, dynamic> json) async {
    await super.save(json); // 端末への保存（今までと同じ）
    _send({'progress': json});
  }

  @override
  Future<void> savePlayerName(String name) async {
    await super.savePlayerName(name);
    _send({'playerName': name});
  }

  // Firestore への送信。待たずに進める（圏外だと送信完了まで時間がかかるため）。
  // 失敗しても端末には保存済みなので、アプリの動作には影響させない
  void _send(Map<String, dynamic> data) {
    _doc
        .set({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((_) {});
  }
}
