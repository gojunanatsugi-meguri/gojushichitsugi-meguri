// 地点・協力店・クイズのデータと、それを探す関数。
// Flutter に依存しないので、印刷物を作るスクリプト（tool/）からも読み込める

// 地点（枚方宿の中の5〜6か所）。スタンプは地点ごとに1つ
class Checkpoint {
  final String id;
  final int order;
  final String name;
  // この地点で出すクイズ。答えは「次の地点の周辺」にある。最後の地点は null
  final Quiz? quiz;

  const Checkpoint({
    required this.id,
    required this.order,
    required this.name,
    this.quiz,
  });
}

// 協力店。1つの地点に複数の店が属する。QRは店ごとに設置する
class Shop {
  final String id;
  final String checkpointId;
  final String name;
  final String category;
  final String coupon;
  final String qrValue;
  final double lat;
  final double lng;
  // 位置確認に失敗したとき、店の方に入力してもらう番号
  final String staffPin;

  const Shop({
    required this.id,
    required this.checkpointId,
    required this.name,
    required this.category,
    required this.coupon,
    required this.qrValue,
    required this.lat,
    required this.lng,
    required this.staffPin,
  });
}

class Quiz {
  final String question;
  final List<String> options;
  final String correctAnswer;
  // ヒントは位に関係なく誰でも見られる
  final String hint;

  const Quiz({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.hint,
  });
}

// 仮データ：実際の地点・クイズ内容は枚方信用金庫様・協力店との
// 打ち合わせを踏まえて Firestore 側に置き換える（Week 1-2 で確定）
// 地点名・座標・クイズ（「（仮）」付き）はすべて仮の値
const List<Checkpoint> checkpoints = [
  Checkpoint(
    id: 'cp1',
    order: 1,
    name: '第1地点',
    quiz: Quiz(
      question: '（仮）次の地点にあるコーヒーのお店。名前に入っている言葉は？',
      options: ['KAORU', 'SAKURA', 'MIDORI'],
      correctAnswer: 'KAORU',
      hint: 'お店の看板をよく見てみましょう。',
    ),
  ),
  Checkpoint(
    id: 'cp2',
    order: 2,
    name: '第2地点',
    quiz: Quiz(
      question: '次の地点に向かう途中、甘い香りがするお店は何のお店？',
      options: ['どら焼き屋', '本屋', '床屋'],
      correctAnswer: 'どら焼き屋',
      hint: '甘い香りは、あんこと生地を焼くにおいかもしれません。',
    ),
  ),
  Checkpoint(
    id: 'cp3',
    order: 3,
    name: '第3地点',
    quiz: Quiz(
      question: '（仮）次の地点のお店では、カフェのほかに何を扱っている？',
      options: ['うつわ', '自転車', 'くすり'],
      correctAnswer: 'うつわ',
      hint: 'お店の名前にヒントがあります。',
    ),
  ),
  Checkpoint(
    id: 'cp4',
    order: 4,
    name: '第4地点',
    quiz: Quiz(
      question: '（仮）次の地点で売られている、枚方名物のお餅の名前は？',
      options: ['くらわんか餅', 'きびだんご', '八つ橋'],
      correctAnswer: 'くらわんか餅',
      hint: '淀川で「食らわんか」と声をかけて食べ物を売った舟にちなんだ名前です。',
    ),
  ),
  Checkpoint(id: 'cp5', order: 5, name: '第5地点'),
];

// QRの中身は「gojushichi:」＋推測できないランダムな文字列。
// 店IDをそのまま入れると、誰でも自分でQRを作れてしまうため。
// 本番用の値は Firestore 側で管理し、アプリには埋め込まない想定
// 座標：shop1（枚方凍氷 三矢町4-1）・shop3（呼人堂 岡本町10-3）・shop5（巴堂 伊加賀北町6-12）は
// 住所から国土地理院の住所検索で取得した値。shop2・shop4 は住所未確認のため仮の値。
// 詳しくは docs/現地確認リスト.md
const List<Shop> shops = [
  Shop(id: 'shop1', checkpointId: 'cp1', name: '枚方涼氷', category: 'かき氷', coupon: '練乳シングルをサービス',
      qrValue: 'gojushichi:3d9103edc06bc9d8', lat: 34.814632, lng: 135.643219, staffPin: '1570'),
  Shop(id: 'shop2', checkpointId: 'cp2', name: 'KAORU COFFEE', category: 'カフェ', coupon: 'ドリンク10%引き',
      qrValue: 'gojushichi:eca15200491a98d4', lat: 34.8168, lng: 135.6455, staffPin: '2756'),
  Shop(id: 'shop3', checkpointId: 'cp3', name: '呼人堂', category: 'どら焼き', coupon: '1,500円以上で1個増量',
      qrValue: 'gojushichi:a99d2f037b7aad51', lat: 34.815006, lng: 135.645966, staffPin: '1998'),
  Shop(id: 'shop4', checkpointId: 'cp4', name: 'うつわとカフェ Lau', category: 'カフェ', coupon: 'お会計より100円引き',
      qrValue: 'gojushichi:02df1fe67ef76483', lat: 34.8185, lng: 135.6418, staffPin: '1461'),
  Shop(id: 'shop5', checkpointId: 'cp5', name: 'くらわんか餅巴堂', category: '餅菓子', coupon: '500円以上でやきもち1個',
      qrValue: 'gojushichi:9a2c4404c797a967', lat: 34.809853, lng: 135.640305, staffPin: '8083'),
];

const qrPrefix = 'gojushichi:';

Shop? findShopByQrValue(String value) => shops.where((s) => s.qrValue == value.trim()).firstOrNull;

Shop? findShopById(String id) => shops.where((s) => s.id == id).firstOrNull;

Checkpoint? findCheckpointById(String? id) => checkpoints.where((c) => c.id == id).firstOrNull;

List<Shop> shopsAt(String checkpointId) => shops.where((s) => s.checkpointId == checkpointId).toList();

Checkpoint? nextCheckpointOf(Checkpoint cp) => checkpoints.where((c) => c.order == cp.order + 1).firstOrNull;

