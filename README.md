# 五十七次めぐり

ソイチャレ2026アイデアコンテスト「五十七次めぐり ― 歩いて、学んで、まちに寄る ―」のアプリ実装。
枚方宿の協力店をQRコードで巡り、クイズに答えてクーポンを獲得し、日々の歩数で宿場印の位が上がっていくウォーキングアプリ。

## 開発環境

- **アプリ本体・画面構築**: Flutter（Dart）
- **QRスキャン**: `mobile_scanner`
- **状態管理**: `provider`
- **バックエンド**: Firebase（Firestore / Authentication / Storage）※未設定、次のステップ
- **歩数取得**: HealthKit / Health Connect 対応パッケージ（未導入、検証予定・最大の技術リスク）

## 今の状態

画面遷移と全体の流れを確認できる状態です。データはすべて仮のサンプル・アプリ内の状態管理（`lib/models/app_state.dart`）で、Firebase にはまだ繋がっていません。

- `スタンプ帳`: 位（ランク）・進捗・獲得済みスタンプ一覧
- `QR読取`: カメラでの読み取りに対応（`mobile_scanner`）。お店を手動で選ぶデモ操作とテスト用QR画面は、デバッグ実行のときだけ表示される
- `クイズ`: 地点ごとに1問（内容は仮）。ヒントは誰でも見られる。回答は1地点1回。正解すると次の地点の協力店から1店を選んでクーポンを獲得
- スタンプ・クイズの回答・選んだクーポンは端末に保存され、アプリを閉じても続きから再開できる（`lib/services/progress_store.dart`）
- 位置確認: QR読取時に「お店の近くか」を確かめる機能は実装済みだが、**初期状態はオフ**（`lib/services/location_check.dart` の `kRequireLocationCheck`）。対外説明「位置情報は現在地表示のみ」を改めるかチームで決めてから有効にする
- `クーポン`: 獲得済みクーポンの一覧
- `地図`: 実際の地図は未実装。スポット一覧のみ

## 開発の始め方

初めて環境を用意する人は [SETUP.md](SETUP.md) を見てください（Flutter のインストールから、アプリを動かすまでの手順）。

```bash
flutter pub get
flutter run -d chrome   # ブラウザでプレビュー
flutter test            # 基本的な動作確認テスト
```

実機・シミュレーターで動かす場合：

```bash
flutter run             # 接続中の実機 / 起動中のシミュレーターを自動選択
```

- iOSでビルドするには Xcode が必要（Mac限定）
- Androidでビルドするには Android Studio（Android SDK）が必要

## やること

- [ ] Firebaseプロジェクトを作成し、Firestore/Authenticationを設定（`firebase_core` / `cloud_firestore` パッケージを追加）
- [ ] 歩数取得パッケージを検証し、デモボタンを実データに置き換える
- [ ] スポット・クイズ・クーポンのデータをFirestoreから読み込むように変更
- [ ] UIの調整（文字サイズ・配色・1画面1情報）
