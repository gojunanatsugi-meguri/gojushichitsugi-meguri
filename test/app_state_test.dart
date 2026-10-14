// スタンプ・クイズ・クーポン選択のルール（AppState）と、位置確認の距離判定のテスト

import 'package:flutter_test/flutter_test.dart';

import 'package:gojushichitsugi_meguri/models/app_state.dart';
import 'package:gojushichitsugi_meguri/services/location_check.dart';

Shop shopOf(String id) => findShopById(id)!;

void main() {
  group('QRの照合', () {
    test('登録されたQRだけが店に対応する', () {
      expect(findShopByQrValue(shopOf('shop1').qrValue)?.id, 'shop1');
      // 以前の推測しやすい形式や、ほかのQRは通らない
      expect(findShopByQrValue('gojushichi:spot1'), isNull);
      expect(findShopByQrValue('https://example.com'), isNull);
    });
  });

  group('スタンプ', () {
    test('同じ地点を読み直してもスタンプは1つ', () {
      final s = AppState();
      expect(s.checkIn(shopOf('shop1')), CheckInResult.newStamp);
      expect(s.checkIn(shopOf('shop1')), CheckInResult.alreadyStamped);
      expect(s.stampedCheckpointIds, {'cp1'});
      expect(s.lastScannedCheckpointId, 'cp1');
    });
  });

  group('クイズ', () {
    test('スタンプを取る前の地点には答えられない', () {
      final s = AppState()..answerQuiz('cp1', 'KAORU');
      expect(s.quizResults, isEmpty);
    });

    test('1地点1回だけ。読み直しても回答はやり直せない', () {
      final s = AppState()..checkIn(shopOf('shop1'));
      s.answerQuiz('cp1', 'SAKURA');
      s.checkIn(shopOf('shop1'));
      s.answerQuiz('cp1', 'KAORU');
      expect(s.quizResults['cp1'], false);
    });

    test('不正解でもスタンプは残り、次の地点のクイズに答えられる', () {
      final s = AppState()..checkIn(shopOf('shop1'));
      s.answerQuiz('cp1', 'SAKURA');
      s.checkIn(shopOf('shop2'));
      s.answerQuiz('cp2', 'どら焼き屋');
      expect(s.stampedCheckpointIds, {'cp1', 'cp2'});
      expect(s.quizResults, {'cp1': false, 'cp2': true});
    });
  });

  group('クーポン', () {
    test('候補は次の地点の協力店', () {
      final s = AppState()..checkIn(shopOf('shop1'));
      expect(s.couponCandidates('cp1').map((e) => e.id), ['shop2']);
    });

    test('不正解ならクーポンは選べない', () {
      final s = AppState()..checkIn(shopOf('shop1'));
      s.answerQuiz('cp1', 'SAKURA');
      s.chooseCoupon('cp1', 'shop2');
      expect(s.obtainedCoupons, isEmpty);
    });

    test('正解すると1店だけ選べる', () {
      final s = AppState()..checkIn(shopOf('shop1'));
      s.answerQuiz('cp1', 'KAORU');
      s.chooseCoupon('cp1', 'shop2');
      s.chooseCoupon('cp1', 'shop2');
      expect(s.obtainedCoupons.map((e) => e.id), ['shop2']);
      expect(s.canChooseCoupon('cp1'), false);
    });

    test('次の地点以外の店は選べない', () {
      final s = AppState()..checkIn(shopOf('shop1'));
      s.answerQuiz('cp1', 'KAORU');
      s.chooseCoupon('cp1', 'shop5');
      expect(s.obtainedCoupons, isEmpty);
    });
  });

  group('位置確認の距離判定', () {
    final shop = shopOf('shop1');

    test('店のすぐそばなら近い', () {
      expect(isNearShop(shop, lat: shop.lat + 0.0005, lng: shop.lng), true); // 約55m
    });

    test('1km離れていれば遠い', () {
      expect(isNearShop(shop, lat: shop.lat + 0.009, lng: shop.lng), false);
    });

    test('GPSの誤差は差し引くが、上限を超える誤差では通さない', () {
      // 約250m：半径200mの外だが、誤差80mを差し引くと内側
      expect(isNearShop(shop, lat: shop.lat + 0.00225, lng: shop.lng, accuracyMeters: 80), true);
      // 約1km：誤差3kmでも上限100mまでしか差し引かない
      expect(isNearShop(shop, lat: shop.lat + 0.009, lng: shop.lng, accuracyMeters: 3000), false);
    });
  });
}
