import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF3700B3);
  static const Color background = Color(0xFF0F0B21);
  static const Color surface = Color(0xFF1E1939);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accent = Color(0xFFBB86FC);
  
  static const Gradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E1939),
      Color(0xFF0F0B21),
    ],
  );
}
