import 'package:health/health.dart';

class HealthService {
  static final Health _health = Health();
  static bool _configured = false;

  // 許可の確認は共通にする
  static Future<bool> _authorize() async {
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }
    return _health.requestAuthorization(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );
  }

  static DateTime _todayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 【新】since から今までの距離(km)。累計用。読めなければ例外
  static Future<double> getDistanceKmSince(DateTime since) async {
    if (!await _authorize()) throw Exception('health not granted');
    final steps = await _health.getTotalStepsInInterval(
      since, DateTime.now(), includeManualEntry: false);
    if (steps == null) throw Exception('no step data');
    return steps * 0.00075;
  }

  /// 【旧】今日の距離(km)。読めなければ 0
  static Future<double> getTodayDistanceKm() async {
    return (await getTodaySteps()) * 0.00075;
  }

  /// 【旧】今日の歩数。読めなければ 0
  static Future<int> getTodaySteps() async {
    if (!await _authorize()) return 0;
    final steps = await _health.getTotalStepsInInterval(
      _todayMidnight(), DateTime.now(), includeManualEntry: false);
    return steps ?? 0;
  }
}