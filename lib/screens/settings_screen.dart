import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  final Language targetLang;
  final ValueChanged<Language> onTargetLangChanged;
  final VoidCallback onLogout;
  final bool isDark;
  final VoidCallback? onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.targetLang,
    required this.onTargetLangChanged,
    required this.onLogout,
    this.isDark = false,
    this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final txColor = isDark ? AppColors.txDark : AppColors.txLight;
    final tx2Color = isDark ? AppColors.tx2Dark : AppColors.tx2Light;
    final tx3Color = isDark ? AppColors.tx3Dark : AppColors.tx3Light;

    return ListView(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text('Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: txColor, letterSpacing: -0.3)),
      ),

      const SectionTitle('Target Language'),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: allLanguages.map((lang) {
            final isSelected = targetLang.apiCode == lang.apiCode;
            return InkWell(
              onTap: () => onTargetLangChanged(lang),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Text('${lang.flag}  ${lang.name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: txColor)),
                  const Spacer(),
                  if (isSelected) Icon(Icons.check_circle_rounded, color: accent, size: 18),
                ]),
              ),
            );
          }).toList(),
        ),
      ),

      const SectionTitle('Appearance'),
      AppCard(
        child: Row(children: [
          Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(isDark ? 'Dark Mode' : 'Light Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: txColor))),
          Switch(value: isDark, onChanged: (_) => onToggleTheme?.call(), activeColor: accent),
        ]),
      ),

      const SectionTitle('Account'),
      AppCard(
        onTap: onLogout,
        child: Row(children: [
          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error)),
        ]),
      ),

      const SectionTitle('About'),
      AppCard(
        child: Column(children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, color: tx3Color, size: 18),
            const SizedBox(width: 10),
            Text('S2S Translator', style: TextStyle(fontSize: 13, color: tx2Color)),
            const Spacer(),
            Text('v1.0.0', style: TextStyle(fontSize: 12, color: tx3Color, fontFamily: 'DM Mono')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.language_rounded, color: tx3Color, size: 18),
            const SizedBox(width: 10),
            Text('English → French, Twi, Ewe, Hausa & Fulani', style: TextStyle(fontSize: 13, color: tx2Color)),
          ]),
        ]),
      ),

      const SizedBox(height: 20),
    ]);
  }
}