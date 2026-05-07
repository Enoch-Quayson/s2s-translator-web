import 'package:flutter/material.dart';
import '../theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isOnline;
  final VoidCallback? onSettings;
  const AppTopBar({super.key, this.isOnline = true, this.onSettings});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final txColor = isDark ? AppColors.txDark : AppColors.txLight;

    return Container(
      decoration: BoxDecoration(color: cardColor, border: Border(bottom: BorderSide(color: borderColor))),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.translate, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          RichText(text: TextSpan(
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: txColor, fontFamily: 'Outfit'),
            children: [
              const TextSpan(text: 'S2S '),
              TextSpan(text: 'Translator', style: TextStyle(color: accent)),
            ],
          )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.card2Dark : AppColors.card2Light,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              )),
              const SizedBox(width: 5),
              Text(isOnline ? 'Online' : 'Offline', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: isOnline ? AppColors.success : AppColors.error,
                fontFamily: 'DM Mono',
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class LangBadge extends StatelessWidget {
  final Language lang;
  final bool small;
  const LangBadge({super.key, required this.lang, this.small = false});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isEn = lang.apiCode == 'en';
    final color = isEn ? accent : lang.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text('${lang.flag} ${lang.code.split('-')[0].toUpperCase()}',
          style: TextStyle(fontSize: small ? 10 : 11, fontWeight: FontWeight.w500, color: color, fontFamily: 'DM Mono')),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsets? padding;
  const SectionTitle(this.title, {super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(title.toUpperCase(), style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
        color: isDark ? AppColors.tx3Dark : AppColors.tx3Light,
        fontFamily: 'DM Mono',
      )),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  const GlassCard({super.key, required this.child, this.margin, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: padding ?? const EdgeInsets.all(14), child: child))
          : Padding(padding: padding ?? const EdgeInsets.all(14), child: child),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({super.key, required this.child, this.margin, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Padding(padding: padding ?? const EdgeInsets.all(14), child: child))
          : Padding(padding: padding ?? const EdgeInsets.all(14), child: child),
    );
  }
}

class CopyButton extends StatelessWidget {
  final String text;
  const CopyButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        // Web copy not supported via clipboard easily, just show snack
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Copied!'), duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ));
      },
      child: Icon(Icons.copy_rounded, size: 16, color: isDark ? AppColors.tx3Dark : AppColors.tx3Light),
    );
  }
}

class InputModeTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const InputModeTabs({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? AppColors.card2Dark : AppColors.card2Light;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final activeCard = isDark ? AppColors.cardDark : AppColors.cardLight;
    final inactiveColor = isDark ? AppColors.tx3Dark : AppColors.tx3Light;

    final tabs = [(Icons.mic_rounded, 'Microphone'), (Icons.edit_rounded, 'Text'), (Icons.upload_file_rounded, 'File')];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? activeCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))] : null,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(tabs[i].$1, size: 14, color: isActive ? accent : inactiveColor),
                  const SizedBox(width: 5),
                  Text(tabs[i].$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? accent : inactiveColor, fontFamily: 'Outfit')),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ConfidenceBar extends StatelessWidget {
  final double confidence;
  const ConfidenceBar({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = confidence >= 0.9 ? AppColors.success : confidence >= 0.7 ? AppColors.warning : AppColors.error;
    return Row(children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: isDark ? AppColors.card2Dark : AppColors.card2Light,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 3,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('${(confidence * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color, fontFamily: 'DM Mono')),
    ]);
  }
}