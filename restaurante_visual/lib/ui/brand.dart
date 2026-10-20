import 'package:flutter/material.dart';

class Brand {
  static const navy = Color(0xFF102A43);
  static const navyLight = Color(0xFF243B53);
  static const teal = Color(0xFF0F766E);
  static const aqua = Color(0xFF14B8A6);
  static const coral = Color(0xFFF97316);
  static const cream = Color(0xFFFFFBF5);
  static const background = Color(0xFFF4F7F8);
  static const ink = Color(0xFF172B4D);
  static const muted = Color(0xFF627D98);
  static const success = Color(0xFF16803C);
  static const danger = Color(0xFFB42318);

  static const radius = 16.0;

  static BoxDecoration panel({Color color = Colors.white}) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE4E7EC)),
    boxShadow: const [
      BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  static ButtonStyle primaryButton() => ElevatedButton.styleFrom(
    backgroundColor: teal,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
