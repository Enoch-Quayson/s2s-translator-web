import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _error;
  bool _obscure = true;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        final res = await ApiService.login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
        if (res['access_token'] != null) { widget.onLoggedIn(); }
        else { setState(() => _error = res['detail'] ?? 'Login failed'); }
      } else {
        final res = await ApiService.register(name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
        if (res['id'] != null) {
          final loginRes = await ApiService.login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
          if (loginRes['access_token'] != null) { widget.onLoggedIn(); }
        } else { setState(() => _error = res['detail'] ?? 'Registration failed'); }
      }
    } catch (e) { setState(() => _error = 'Connection error. Check your API server.'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final txColor = isDark ? AppColors.txDark : AppColors.txLight;
    final tx2Color = isDark ? AppColors.tx2Dark : AppColors.tx2Light;
    final tx3Color = isDark ? AppColors.tx3Dark : AppColors.tx3Light;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.translate, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('S2S Translator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: txColor, letterSpacing: -0.3)),
                Text('English → French, Twi & more', style: TextStyle(fontSize: 12, color: tx2Color)),
              ]),
            ]),
            const SizedBox(height: 40),
            Text(_isLogin ? 'Welcome back' : 'Create account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: txColor, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(_isLogin ? 'Sign in to continue' : 'Start translating for free', style: TextStyle(fontSize: 14, color: tx2Color)),
            const SizedBox(height: 28),
            if (!_isLogin) ...[
              _inputField('Full Name', _nameCtrl, Icons.person_outline_rounded, txColor, tx3Color, cardColor, borderColor),
              const SizedBox(height: 12),
            ],
            _inputField('Email', _emailCtrl, Icons.email_outlined, txColor, tx3Color, cardColor, borderColor, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _inputField('Password', _passwordCtrl, Icons.lock_outline_rounded, txColor, tx3Color, cardColor, borderColor,
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: tx3Color),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error))),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                child: RichText(text: TextSpan(
                  style: TextStyle(fontSize: 13, color: tx2Color, fontFamily: 'Outfit'),
                  children: [
                    TextSpan(text: _isLogin ? "Don't have an account? " : 'Already have an account? '),
                    TextSpan(text: _isLogin ? 'Sign up' : 'Sign in', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                  ],
                )),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl, IconData icon, Color txColor, Color tx3Color, Color cardColor, Color borderColor, {bool obscure = false, TextInputType? keyboardType, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: TextField(
        controller: ctrl, obscureText: obscure, keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: txColor, fontFamily: 'Outfit'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: tx3Color, fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: tx3Color),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}