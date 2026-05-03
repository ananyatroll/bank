import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTeleBankTheme() {
  const seed = Color(0xFF14A39A);
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      background: const Color(0xFFF7F5EF),
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
    scaffoldBackgroundColor: const Color(0xFFF7F5EF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F5EF),
      foregroundColor: Color(0xFF0E1B2A),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
