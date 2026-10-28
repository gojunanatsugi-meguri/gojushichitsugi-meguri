// 地点・店の初期データを Firestore に入れるスクリプト（最初に1回だけ、または内容を変えたとき）
//
// 使い方（tool/firestore_seed フォルダで）:
//   1. Firebase コンソール → プロジェクトの設定 → サービスアカウント → 「新しい秘密鍵を生成」
//      ダウンロードしたファイルを serviceAccountKey.json という名前でこのフォルダに置く
//      ※ これは管理者の鍵。絶対に Git にコミットしない（.gitignore に追加済みか確認）
//   2. npm init -y
//   3. npm install firebase-admin
//   4. node seed_firestore.js
//
// 管理者の鍵で書き込むので、セキュリティルール（書き換え禁止）に関係なく書ける。
// 同じ id の文書は上書きされるので、何度実行しても重複しない
// ※ firebase-admin の新しい版に合わせた書き方（admin.credential は使えない）
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');
const data = require('./seed_data.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  const batch = db.batch(); // まとめて書き込む（全部成功するか、全部失敗するか）

  for (const cp of data.checkpoints) {
    const { id, ...rest } = cp; // id は文書の名前にして、中身からは外す
    batch.set(db.collection('checkpoints').doc(id), rest);
  }
  for (const shop of data.shops) {
    const { id, ...rest } = shop;
    batch.set(db.collection('shops').doc(id), rest);
  }

  await batch.commit();
  console.log(`書き込み完了: 地点 ${data.checkpoints.length} 件・店 ${data.shops.length} 件`);
}

main().catch((e) => {
  console.error('失敗しました:', e);
  process.exit(1);
});
