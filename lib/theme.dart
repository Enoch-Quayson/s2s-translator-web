import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Glacier Blue palette
  static const primary = Color(0xFF446E87);      // Marine
  static const primaryDark = Color(0xFF1D4052);  // Harbor
  static const primaryLight = Color(0xFF72A3BF); // Glacier

  static const secondary = Color(0xFF72A3BF);    // Glacier
  static const secondaryDark = Color(0xFF446E87);
  static const tertiary = Color(0xFF9BBFCF);

  // Dark mode surfaces
  static const bgDark = Color(0xFF030F18);        // Depth
  static const cardDark = Color(0xFF0D1E28);
  static const card2Dark = Color(0xFF162836);
  static const borderDark = Color(0xFF1D4052);    // Harbor
  static const txDark = Color(0xFFE0E8E6);        // Frost
  static const tx2Dark = Color(0xFF9BBFCF);       // Glacier mid
  static const tx3Dark = Color(0xFF446E87);       // Marine

  // Light mode surfaces
  static const bgLight = Color(0xFFE0E8E6);       // Frost
  static const cardLight = Color(0xFFFFFFFF);
  static const card2Light = Color(0xFFEEF3F5);
  static const borderLight = Color(0xFFBDD0D9);
  static const txLight = Color(0xFF030F18);       // Depth
  static const tx2Light = Color(0xFF1D4052);      // Harbor
  static const tx3Light = Color(0xFF446E87);      // Marine

  // Status colors
  static const success = Color(0xFF2E9E6B);
  static const successLight = Color(0x1A2E9E6B);
  static const warning = Color(0xFFB07D2A);
  static const warningLight = Color(0x1AB07D2A);
  static const error = Color(0xFFB03A3A);
  static const errorLight = Color(0x1AB03A3A);

  // Language colors — all from the glacier palette family
  static const french = Color(0xFF446E87);    // Marine
  static const twi = Color(0xFF2E7D6B);
  static const ewe = Color(0xFF5A8FA3);
  static const hausa = Color(0xFF1D4052);     // Harbor
  static const fulani = Color(0xFF72A3BF);    // Glacier
  static const english = Color(0xFF446E87);

  static const List<Color> accentOptions = [
    Color(0xFF446E87), // Marine
    Color(0xFF1D4052), // Harbor
    Color(0xFF72A3BF), // Glacier
    Color(0xFF2E9E6B), // Green
    Color(0xFF5A6E87), // Muted blue
    Color(0xFF7A4E87), // Muted purple
  ];
}

class AppTheme {
  static ThemeData buildLight(Color accent) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      background: AppColors.bgLight,
      surface: AppColors.cardLight,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    textTheme: GoogleFonts.outfitTextTheme(),
    inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, filled: false),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.bgLight, elevation: 0, scrolledUnderElevation: 0),
  );

  static ThemeData buildDark(Color accent) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      background: AppColors.bgDark,
      surface: AppColors.cardDark,
    ),
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, filled: false),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.bgDark, elevation: 0, scrolledUnderElevation: 0),
  );
}

class Language {
  final String code;
  final String name;
  final String flag;
  final String apiCode;
  final Color color;
  const Language({required this.code, required this.name, required this.flag, required this.apiCode, required this.color});
}

const langEnglish = Language(code: 'en', name: 'English', flag: '🇬🇧', apiCode: 'en', color: AppColors.english);
const langFrench = Language(code: 'fr', name: 'French', flag: '🇫🇷', apiCode: 'fr', color: AppColors.french);
const langTwi = Language(code: 'tw', name: 'Asante Twi', flag: '🇬🇭', apiCode: 'tw', color: AppColors.twi);
const langEwe = Language(code: 'ee', name: 'Ewe', flag: '🇬🇭', apiCode: 'ee', color: AppColors.ewe);
const langHausa = Language(code: 'hau', name: 'Hausa', flag: '🇬🇭', apiCode: 'hau', color: AppColors.hausa);
const langFulani = Language(code: 'fuv', name: 'Fulani', flag: '🇬🇭', apiCode: 'fuv', color: AppColors.fulani);

const List<Language> allLanguages = [langFrench, langTwi, langEwe, langHausa, langFulani];

const List<Map<String, dynamic>> phraseCategories = [
  {'id': 'greetings', 'label': 'Greetings', 'icon': '👋', 'color': Color(0xFF446E87)},
  {'id': 'medical', 'label': 'Medical', 'icon': '🏥', 'color': Color(0xFFB03A3A)},
  {'id': 'travel', 'label': 'Travel', 'icon': '✈️', 'color': Color(0xFF2E9E6B)},
  {'id': 'business', 'label': 'Business', 'icon': '💼', 'color': Color(0xFFB07D2A)},
  {'id': 'food', 'label': 'Food', 'icon': '🍽️', 'color': Color(0xFF72A3BF)},
  {'id': 'emergency', 'label': 'Emergency', 'icon': '🚨', 'color': Color(0xFFB03A3A)},
  {'id': 'saved', 'label': 'Saved', 'icon': '❤️', 'color': Color(0xFF446E87)},
];
