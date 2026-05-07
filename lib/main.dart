import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'services/api_service.dart';
import 'widgets/common.dart';
import 'screens/home_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/history_screen.dart';
import 'screens/phrases_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const S2SApp());
}

class S2SApp extends StatefulWidget {
  const S2SApp({super.key});
  static _S2SAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_S2SAppState>();
  @override
  State<S2SApp> createState() => _S2SAppState();
}

class _S2SAppState extends State<S2SApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Color _accent = AppColors.primary;

  @override
  void initState() { super.initState(); _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    final accentIdx = prefs.getInt('accent_index') ?? 0;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _accent = AppColors.accentOptions[accentIdx.clamp(0, AppColors.accentOptions.length - 1)];
    });
  }

  Future<void> toggleTheme() async {
    final isDark = _themeMode == ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', !isDark);
    setState(() => _themeMode = isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setAccent(Color color) async {
    final idx = AppColors.accentOptions.indexOf(color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_index', idx >= 0 ? idx : 0);
    setState(() => _accent = color);
  }

  bool get isDark => _themeMode == ThemeMode.dark;
  Color get accent => _accent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S2S Translator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLight(_accent),
      darkTheme: AppTheme.buildDark(_accent),
      themeMode: _themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _isLoggedIn;

  @override
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() => _isLoggedIn = token != null && token.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final accent = S2SApp.of(context)?.accent ?? AppColors.primary;
    if (_isLoggedIn == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: accent)));
    }
    if (!_isLoggedIn!) {
      return LoginScreen(onLoggedIn: () => setState(() => _isLoggedIn = true));
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  Language _targetLang = langFrench;
  bool _isOnline = false;

  @override
  void initState() { super.initState(); _checkOnline(); }

  Future<void> _checkOnline() async {
    final ok = await ApiService.checkHealth();
    if (mounted) setState(() => _isOnline = ok);
  }

  void _onTargetLangChanged(Language lang) => setState(() => _targetLang = lang);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      HomeScreen(
        targetLang: _targetLang,
        onTargetLangChanged: _onTargetLangChanged,
        onTranslateTap: () => setState(() => _currentIndex = 2),
      ),
      const HistoryScreen(),
      TranslateScreen(targetLang: _targetLang),
      const PhrasebookScreen(),
      SettingsScreen(
        targetLang: _targetLang,
        onTargetLangChanged: _onTargetLangChanged,
        isDark: isDark,
        onToggleTheme: () => S2SApp.of(context)?.toggleTheme(),
        onLogout: () async {
          await ApiService.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LoginScreen(
                onLoggedIn: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (_) => false,
                ),
              )),
              (_) => false,
            );
          }
        },
      ),
    ];

    return Scaffold(
      appBar: AppTopBar(isOnline: _isOnline),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  const _BottomNav({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = S2SApp.of(context)?.accent ?? AppColors.primary;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(color: cardColor, border: Border(top: BorderSide(color: borderColor))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', active: currentIndex == 0, onTap: () => onChanged(0), accent: accent),
              _NavItem(icon: Icons.history_rounded, label: 'History', active: currentIndex == 1, onTap: () => onChanged(1), accent: accent),
              GestureDetector(
                onTap: () => onChanged(2),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
                ),
              ),
              _NavItem(icon: Icons.menu_book_rounded, label: 'Phrases', active: currentIndex == 3, onTap: () => onChanged(3), accent: accent),
              _NavItem(icon: Icons.settings_rounded, label: 'Settings', active: currentIndex == 4, onTap: () => onChanged(4), accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color accent;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.tx3Dark : AppColors.tx3Light;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? accent : inactiveColor),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: active ? accent : inactiveColor, fontFamily: 'Outfit')),
          ],
        ),
      ),
    );
  }
}
