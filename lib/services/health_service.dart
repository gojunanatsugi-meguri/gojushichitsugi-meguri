import 'package:health/health.dart';

class HealthService {
  static final Health _health = Health();

  /// 今日の歩数をkmに換算して返す（歩けなければ0）
  /// 平均歩幅 0.75m で換算
  static Future<double> getTodayDistanceKm() async {
    final granted = await _health.requestAuthorization([HealthDataType.STEPS]);
    if (!granted) return 0;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final steps = await _health.getTotalStepsInInterval(midnight, now);
    return ((steps ?? 0) * 0.00075);
  }

  static Future<int> getTodaySteps() async {
  final granted = await _health.requestAuthorization([HealthDataType.STEPS]);
  if (!granted) return 0;
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  final steps = await _health.getTotalStepsInInterval(midnight, now);
  return steps ?? 0;
}
}