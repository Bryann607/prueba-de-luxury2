import 'package:flutter/material.dart';
// Paleta del prototipo: marrón casi negro, ámbar, rojo ají, verde limón.
const lxBrand = Color(0xFF2A0F0D), lxBrand2 = Color(0xFF3A1A16), lxGold = Color(0xFFE48424), lxBg = Color(0xFFF5F0EB);
const lxInk = Color(0xFF241010), lxMuted = Color(0xFF6B5750), lxLine = Color(0xFFE7DCD3);
const lxGreen = Color(0xFF7FB519), lxRed = Color(0xFFC81D25);
final luxuryTheme = ThemeData(
  useMaterial3: true, scaffoldBackgroundColor: lxBg,
  colorScheme: ColorScheme.fromSeed(seedColor: lxGold, primary: lxGold, onPrimary: lxInk, surface: Colors.white),
  appBarTheme: const AppBarTheme(backgroundColor: lxBrand, foregroundColor: Colors.white),
  cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: lxLine))),
  filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: lxGold, foregroundColor: lxInk,
    minimumSize: const Size(48, 48), textStyle: const TextStyle(fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: lxLine))),
);
