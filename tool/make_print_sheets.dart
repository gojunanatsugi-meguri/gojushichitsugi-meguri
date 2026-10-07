// 協力店に配る印刷物（A4）を作る。
//   dart run tool/make_print_sheets.dart
// build/print/qr_sheets.html ができるので、Chrome で開いて印刷（PDFに保存）する。
// 1店につき2ページ：
//   1枚目 お店に貼る掲示（QRコード）
//   2枚目 店員さん用の説明（確認番号つき。お客さんに見えない場所に保管してもらう）
// 地点・協力店のデータ（lib/models/meguri_data.dart）を変えたら、もう一度実行すれば作り直せる

import 'dart:io';

import 'package:gojushichitsugi_meguri/models/meguri_data.dart';
import 'package:qr/qr.dart';

void main() {
  final pages = StringBuffer();
  for (final shop in shops) {
    final cp = findCheckpointById(shop.checkpointId)!;
    pages
      ..write(_posterPage(shop, cp))
      ..write(_staffPage(shop, cp));
  }

  final out = File('build/print/qr_sheets.html');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(_html(pages.toString()));
  stdout.writeln('${shops.length}店分（${shops.length * 2}ページ）を作りました: ${out.path}');
}

String _posterPage(Shop shop, Checkpoint cp) => '''
<section class="page poster">
  <p class="brand">五十七次めぐり</p>
  <p class="checkpoint">${_esc(cp.name)}</p>
  <h1>${_esc(shop.name)}</h1>
  <div class="qr">${_qrSvg(shop.qrValue)}</div>
  <p class="howto">アプリの<strong>「QR読取」</strong>で<br>このコードを読み取ると<br><strong>スタンプ</strong>がもらえます</p>
</section>
''';

String _staffPage(Shop shop, Checkpoint cp) => '''
<section class="page staff">
  <p class="label">お店の方へ（この紙は掲示しないでください）</p>
  <h2>${_esc(shop.name)} 様（${_esc(cp.name)}）</h2>
  <p>「五十七次めぐり」にご協力いただき、ありがとうございます。</p>
  <h3>確認番号</h3>
  <p class="pin">${_esc(shop.staffPin)}</p>
  <h3>この番号を使うとき</h3>
  <p>お客様のスマートフォンに<br>「〇〇の近くにいることを確かめられませんでした」<br>と表示されたら、<strong>「お店の方に確認してもらう」</strong>を押していただき、上の確認番号を入力してください。</p>
  <p>お店の中では電波の都合で位置がずれることがあります。お客様が実際にご来店されていれば、入力していただいて問題ありません。</p>
  <h3>クーポンについて</h3>
  <p>内容：${_esc(shop.coupon)}</p>
  <p>お客様がアプリの「クーポン」画面を見せたら、内容をご確認のうえサービスをお願いします。</p>
  <p class="note">掲示用のQRコードがはがれたり汚れたりした場合は、運営までご連絡ください。</p>
</section>
''';

// QRコードを SVG で描く。印刷しても粗くならないよう、画像ではなく図形で出力する
String _qrSvg(String data) {
  final image = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));
  const quiet = 4; // QRの規格で必要な周りの余白（モジュール4つ分）
  final size = image.moduleCount + quiet * 2;
  final path = StringBuffer();
  for (var y = 0; y < image.moduleCount; y++) {
    for (var x = 0; x < image.moduleCount; x++) {
      if (image.isDark(y, x)) path.write('M${x + quiet} ${y + quiet}h1v1h-1z');
    }
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" shape-rendering="crispEdges">'
      '<rect width="$size" height="$size" fill="#fff"/><path d="$path" fill="#000"/></svg>';
}

String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

String _html(String pages) => '''
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>五十七次めぐり 協力店用QR</title>
<style>
  @page { size: A4; margin: 0; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: "Hiragino Kaku Gothic ProN", "Yu Gothic", "Meiryo", sans-serif; color: #241F1B; background: #ccc; }
  .page { width: 210mm; height: 297mm; padding: 18mm; margin: 8mm auto; background: #fff; page-break-after: always; overflow: hidden; }
  .poster { text-align: center; background: #F6F1E7; border: 3mm solid #2B4A63; }
  .brand { font-size: 16pt; letter-spacing: .3em; color: #2B4A63; margin: 4mm 0 0; }
  .checkpoint { font-size: 22pt; color: #A9782F; margin: 6mm 0 0; font-weight: 700; }
  .poster h1 { font-size: 34pt; margin: 4mm 0 8mm; }
  .qr { width: 120mm; height: 120mm; margin: 0 auto; }
  .qr svg { width: 100%; height: 100%; }
  .howto { font-size: 24pt; line-height: 1.6; margin-top: 10mm; }
  .staff { font-size: 13pt; line-height: 1.7; }
  .staff .label { display: inline-block; background: #B23A2E; color: #fff; padding: 1mm 4mm; font-weight: 700; }
  .staff h2 { font-size: 20pt; margin: 6mm 0 2mm; }
  .staff h3 { font-size: 14pt; margin: 8mm 0 1mm; border-bottom: .4mm solid #E1D5C0; color: #2B4A63; }
  .pin { font-size: 40pt; font-weight: 700; letter-spacing: .4em; margin: 2mm 0; }
  .note { margin-top: 10mm; color: #6E6255; font-size: 11pt; }
  @media print { body { background: #fff; } .page { margin: 0; } }
</style>
</head>
<body>
$pages</body>
</html>
''';
