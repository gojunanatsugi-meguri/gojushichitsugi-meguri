import 'package:flutter/material.dart';

// Vue版のCSS変数と同じ配色にしている
class AppColors {
  static const paper = Color(0xFFF6F1E7);
  static const ink = Color(0xFF241F1B);
  static const inkSoft = Color(0xFF6E6255);
  static const line = Color(0xFFE1D5C0);
  static const indigo = Color(0xFF2B4A63);
  static const indigoSoft = Color(0xFFDCE7EE);
  static const gold = Color(0xFFA9782F);
  // 朱色（スタート画面の筆の丸・「枚方宿」の印）
  static const shu = Color(0xFFB8402F);
  static const indigoDeep = Color(0xFF1F3550);
}

final appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    surface: AppColors.paper,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
  ),
  useMaterial3: true,
);
