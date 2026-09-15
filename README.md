# 五十七次めぐり

ソイチャレ2026アイデアコンテスト「五十七次めぐり ― 歩いて、学んで、まちに寄る ―」のアプリ実装。
枚方宿の協力店をQRコードで巡り、クイズに答えてクーポンを獲得し、日々の歩数で宿場印の位が上がっていくウォーキングアプリ。

## 技術スタック

- **画面構築**: Vue 3 + Vite
- **アプリ化**: Capacitor（iOS / Android 両対応）
- **バックエンド**: Firebase（Firestore / Authentication / Storage）※未設定、次のステップ
- **QRスキャン**: `@capacitor-mlkit/barcode-scanning`（未導入、Week2で検証予定）
- **歩数取得**: HealthKit / Health Connect 用プラグイン（未導入、Week2で検証予定・最大の技術リスク）

## 今の状態

画面遷移と全体の流れを確認できる状態です。データはすべて仮のサンプル・ローカルの状態管理（`src/store/appState.js`）で、Firebase にはまだ繋がっていません。

- `スタンプ帳`（ホーム）: 位（ランク）・進捗・獲得済みスタンプ一覧
- `QR読取`: 実際のカメラ読み取りはまだ。お店を選ぶとスタンプ獲得のデモ動作
- `クイズ`: 固定の1問。正解すると次のスポット候補からクーポンを選べる
- `クーポン`: 獲得済みクーポンの一覧
- `地図`: 実際の地図は未実装。スポット一覧のみ

## 開発の始め方

```bash
npm install
npm run dev       # ブラウザでプレビュー（http://localhost:5173）
npm run build      # 本番ビルド
```

## Capacitorでアプリ化する（次のステップ）

```bash
npm run build
npx cap add ios       # 要 Xcode（Command Line Toolsだけでは不可）
npx cap add android    # 要 Android Studio
npx cap sync
npx cap open ios        # Xcodeで開く
npx cap open android    # Android Studioで開く
```

## やること

- [ ] Firebaseプロジェクトを作成し、Firestore/Authenticationを設定
- [ ] `@capacitor-mlkit/barcode-scanning` を導入し、実際のQR読み取りに置き換える
- [ ] 歩数取得プラグインを検証し、デモボタンを実データに置き換える
- [ ] スポット・クイズ・クーポンのデータをFirestoreから読み込むように変更
- [ ] シニア向けUIの最終調整（文字サイズ・配色・1画面1情報）
