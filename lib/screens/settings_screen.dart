import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/how_to_sheet.dart';

// 設定画面。高齢の方が困ったときに見る場所なので、操作する項目は増やさず
// 「使い方」「位置情報・歩数の状態」「アプリについて」だけを置く。
// ログイン機能ができたら、ここに「アカウント」を足す
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _LocationStatus { on, notAsked, denied, serviceOff, unknown }

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  _LocationStatus? _location;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // スマホの設定で許可を変えて戻ってきたときに、表示を新しくする
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkLocation();
  }

  Future<void> _checkLocation() async {
    _LocationStatus status;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        status = _LocationStatus.serviceOff;
      } else {
        status = switch (await Geolocator.checkPermission()) {
          LocationPermission.always || LocationPermission.whileInUse => _LocationStatus.on,
          LocationPermission.denied => _LocationStatus.notAsked,
          LocationPermission.deniedForever => _LocationStatus.denied,
          _ => _LocationStatus.unknown,
        };
      }
    } catch (_) {
      // パソコンやテストなど、位置情報が使えない環境
      status = _LocationStatus.unknown;
    }
    if (mounted) setState(() => _location = status);
  }

  Future<void> _fixLocation() async {
    try {
      switch (_location) {
        case _LocationStatus.notAsked:
          await Geolocator.requestPermission();
        case _LocationStatus.serviceOff:
          await Geolocator.openLocationSettings();
        default:
          await Geolocator.openAppSettings();
      }
    } catch (_) {}
    await _checkLocation();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        title: const Text('設定', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionTitle('使い方'),
          _Item(
            icon: Icons.help_outline,
            title: '使い方を見る',
            onTap: () => showHowTo(context),
          ),
          const _SectionTitle('位置情報と歩数'),
          _locationItem(),
          _stepsItem(appState),
          const _SectionTitle('アプリについて'),
          _Item(
            icon: Icons.privacy_tip_outlined,
            title: '情報の扱いについて',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _PrivacyScreen())),
          ),
          const _Item(icon: Icons.map_outlined, title: '地図の出典', subtitle: '© OpenStreetMap の協力者'),
          _Item(
            icon: Icons.description_outlined,
            title: 'ライセンス',
            onTap: () => showLicensePage(context: context, applicationName: '五十七次めぐり'),
          ),
        ],
      ),
    );
  }

  Widget _locationItem() {
    final (String text, String? button) = switch (_location) {
      null => ('確かめています…', null),
      _LocationStatus.on => ('オン（現在地を地図に出せます）', null),
      _LocationStatus.notAsked => ('まだ許可されていません', '位置情報を許可する'),
      _LocationStatus.denied => ('オフ（現在地と、地点までの歩数が出ません）', 'スマホの設定を開く'),
      _LocationStatus.serviceOff => ('スマホの位置情報サービスがオフです', 'スマホの設定を開く'),
      _LocationStatus.unknown => ('確かめられませんでした', null),
    };
    return _Item(
      icon: Icons.location_on_outlined,
      title: '位置情報',
      subtitle: text,
      action: button == null
          ? null
          : OutlinedButton(
              onPressed: _fixLocation,
              child: Text(button, style: const TextStyle(fontSize: 16)),
            ),
    );
  }

  // iPhone は、歩数の読み取りを許可したかどうかをアプリから確かめられない。
  // そのため状態は出さず、今日の歩数と、0のままのときの許可のしかたを案内する
  Widget _stepsItem(AppState appState) {
    // Android のときだけ Android の手順にする（Chrome などで動かしたときは iPhone の手順を出す）
    final howTo = defaultTargetPlatform == TargetPlatform.android
        ? const ['「ヘルスコネクト」を開く', '「アプリの権限」を押す', '「五十七次めぐり」を押す', '「歩数」を許可する']
        : const ['「設定」アプリを開く', '「プライバシーとセキュリティ」を押す', '「ヘルスケア」を押す', '「五十七次めぐり」を押す', '「歩数」をオンにする'];
    return _Item(
      icon: Icons.directions_walk,
      title: '歩数',
      subtitle: '今日の歩数：${_withComma(appState.stepCount)}歩',
      note: '歩数が0のままの場合は次の手順で許可してください。',
      action: _NumberedSteps(howTo),
    );
  }
}

// 「1. ○○を開く」のような番号付きの手順
class _NumberedSteps extends StatelessWidget {
  const _NumberedSteps(this.steps);

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.indigo,
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(steps[i], style: const TextStyle(fontSize: 16, color: AppColors.ink))),
              ],
            ),
          ),
      ],
    );
  }
}

String _withComma(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
    );
  }
}

// 設定の1行。押せる行には右に矢印を出す。note は小さな説明、action は下に出すボタン
class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, this.subtitle, this.note, this.action, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? note;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.indigo, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, color: AppColors.ink)),
                    if (subtitle case final s?) ...[
                      const SizedBox(height: 2),
                      Text(s, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
                    ],
                    if (note case final n?) ...[
                      const SizedBox(height: 6),
                      Text(n, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                    ],
                    if (action case final a?) ...[
                      const SizedBox(height: 8),
                      a,
                    ],
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

// 位置情報・歩数・めぐりの記録を、何に使っているかの説明。
// 正式なプライバシーポリシー（App Store に出すときに必要）ができたら、内容をそちらに合わせる
class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('位置情報', '現在地を地図に出すことと、地点までの歩数の目安を出すことに使います。位置情報は保存も送信もしません。'),
      ('歩数', 'iPhoneの「ヘルスケア」（Androidは「ヘルスコネクト」）から今日の歩数を読み取り、画面に出すことに使います。歩数は送信しません。'),
      ('めぐりの記録', 'スタンプ・クイズの答え・クーポンの記録は、スマホの中と運営のサーバーに保存し、参加した人数などの集計に使います。お名前や連絡先はいただきません。'),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        title: const Text('情報の扱いについて', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (title, body) in items) ...[
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.ink)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
