// lib/utils/trait_styles.dart

import 'package:flutter/material.dart';

class TraitStyle {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const TraitStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}

class TraitStyles {
  static const Map<String, TraitStyle> traitsMap = {
    'Crested': TraitStyle(
      backgroundColor: Color(0xFFF3E5F5), // Soft purple
      textColor: Color(0xFF7B1FA2),
      icon: Icons.emoji_events_outlined,
    ),
    'Silver Appleyard': TraitStyle(
      backgroundColor: Color(0xFFEFEBE9), // Golden-brown
      textColor: Color(0xFF5D4037),
      icon: Icons.flutter_dash,
    ),
    'Swedish Blue': TraitStyle(
      backgroundColor: Color(0xFFECEFF1), // Slate blue
      textColor: Color(0xFF37474F),
      icon: Icons.shield_outlined,
    ),
    'High Production': TraitStyle(
      backgroundColor: Color(0xFFE8F5E9), // Emerald green
      textColor: Color(0xFF2E7D32),
      icon: Icons.egg_outlined,
    ),
    'Show Quality': TraitStyle(
      backgroundColor: Color(0xFFFFEBEE), // Deep ruby
      textColor: Color(0xFFC62828),
      icon: Icons.star_border,
    ),
  };

  static TraitStyle getStyle(String traitName) {
    return traitsMap[traitName] ?? const TraitStyle(
      backgroundColor: Color(0xFFF5F5F5), // Grey default
      textColor: Color(0xFF616161),
      icon: Icons.info_outline,
    );
  }
}
