import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import 'name_screen.dart';

// 設定画面。今は名前の変更だけ。あとで文字の大きさなどを足せるよう、一覧の形にしている
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        title: const Text('設定', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Material(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading: const Icon(Icons.person_outline, color: AppColors.indigo, size: 28),
              title: const Text('お名前', style: TextStyle(fontSize: 18)),
              subtitle: Text(appState.playerName ?? '未設定', style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NameScreen(editing: true)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
