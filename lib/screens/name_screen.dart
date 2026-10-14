import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'root_screen.dart';

// 初めて使うときに名前（ニックネーム可）を入力してもらう画面。
// 今は端末に保存するだけ。Firebase に接続したら、ここでアカウントと結びつける想定
// editing: スタート画面の設定ボタンから開いたとき。入力済みの名前を変えて、元の画面に戻る
class NameScreen extends StatefulWidget {
  const NameScreen({super.key, this.editing = false});

  final bool editing;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final _controller = TextEditingController(text: context.read<AppState>().playerName ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    context.read<AppState>().setPlayerName(_controller.text);
    if (widget.editing) {
      Navigator.of(context).pop();
      return;
    }
    // 戻るボタンでスタート画面や名前の入力に戻らないよう、それまでの画面を閉じる
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.paper),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('お名前を教えてください',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 12),
            const Text('ニックネームでもかまいません。',
                style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: AppState.playerNameMaxLength,
              style: const TextStyle(fontSize: 24),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '例：ひらかた太郎',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            BigButton(
                label: widget.editing ? 'この名前にする' : 'これではじめる',
                filled: true,
                onPressed: _canSubmit ? _submit : null),
          ],
        ),
      ),
    );
  }
}
