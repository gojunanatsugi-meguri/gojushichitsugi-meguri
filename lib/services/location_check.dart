import 'package:geolocator/geolocator.dart';
import '../models/app_state.dart';

// QR読取時に「お店の近くにいるか」を1回だけ確かめるか。
// 対外的には「位置情報は現在地表示のみ」と説明しているため、
// チームで説明文を改めると決めるまでは false のままにしておく
const bool kRequireLocationCheck = false;

// 市街地や店内ではGPSが数十mずれるので、余裕を持たせた半径にしている
const double kArrivalRadiusMeters = 200;

enum LocationCheckResult { near, far, unavailable }

// 位置は端末の中で距離を比べるだけに使い、保存も送信もしない
Future<LocationCheckResult> checkNearShop(Shop shop) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationCheckResult.unavailable;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return LocationCheckResult.unavailable;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return isNearShop(
      shop,
      lat: position.latitude,
      lng: position.longitude,
      accuracyMeters: position.accuracy,
    )
        ? LocationCheckResult.near
        : LocationCheckResult.far;
  } catch (_) {
    // タイムアウトや端末側のエラー。利用者を止めず、店の方の確認に回す
    return LocationCheckResult.unavailable;
  }
}

// GPSの誤差（accuracy）の分だけ近い側に寄せて判定する。
// 誤差が大きいときに、本当は近くにいる人を「遠い」と判定しないため。
// ただしパソコンなど誤差が数kmになる環境で家から通ってしまわないよう、上限を設ける
const double kMaxAccuracyAllowanceMeters = 100;

bool isNearShop(Shop shop, {required double lat, required double lng, double accuracyMeters = 0}) {
  final distance = Geolocator.distanceBetween(lat, lng, shop.lat, shop.lng);
  final allowance = accuracyMeters.clamp(0, kMaxAccuracyAllowanceMeters);
  return distance - allowance <= kArrivalRadiusMeters;
}
