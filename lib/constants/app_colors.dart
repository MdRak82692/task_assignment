import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5200FF);
  static const Color secondary = Color(0xFF3700B3);
  static const Color background = Color(0xFF0B0024);
  static const Color surface = Color(0xFF082257);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accent = Color(0xFF5200FF);
  static const Color unselectedIndicator = Color(0x33BA99FF);

  static const Gradient mainGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFF082257),
      Color(0xFF0B0024),
    ],
  );
}
