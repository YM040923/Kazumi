import 'package:flutter/material.dart';

class KazumiThemePreset {
  const KazumiThemePreset({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.lightSurface,
    required this.darkSurface,
  });

  final String id;
  final String label;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color lightSurface;
  final Color darkSurface;

  bool get isDefault => id == 'default';
  Color get color => primary;
  String get storageValue => isDefault ? 'default' : 'preset:$id';

  static KazumiThemePreset? fromStorageValue(String? value) {
    final stored = value ?? 'default';
    if (stored == 'default') return defaultThemePreset;
    const prefix = 'preset:';
    final id =
        stored.startsWith(prefix) ? stored.substring(prefix.length) : stored;
    for (final preset in colorThemeTypes) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

const defaultThemePreset = KazumiThemePreset(
  id: 'default',
  label: '默认',
  primary: Colors.green,
  secondary: Colors.teal,
  tertiary: Colors.lightGreen,
  lightSurface: Color(0xFFF8F8F8),
  darkSurface: Color(0xFF0D0D0D),
);

const List<KazumiThemePreset> colorThemeTypes = [
  defaultThemePreset,
  KazumiThemePreset(
    id: 'midnightNeon',
    label: '午夜霓虹',
    primary: Color(0xFF00A7D8),
    secondary: Color(0xFFD8577F),
    tertiary: Color(0xFF8C7CF6),
    lightSurface: Color(0xFFF2F9FC),
    darkSurface: Color(0xFF07111A),
  ),
  KazumiThemePreset(
    id: 'blueCinema',
    label: '蓝调影院',
    primary: Color(0xFF3D6FB6),
    secondary: Color(0xFF1F8A7A),
    tertiary: Color(0xFF6E7BD9),
    lightSurface: Color(0xFFF4F7FB),
    darkSurface: Color(0xFF0D111A),
  ),
  KazumiThemePreset(
    id: 'filmTeal',
    label: '胶片暖青',
    primary: Color(0xFF1F8A7A),
    secondary: Color(0xFF3D6FB6),
    tertiary: Color(0xFFE7B95F),
    lightSurface: Color(0xFFF4FAF7),
    darkSurface: Color(0xFF071715),
  ),
  KazumiThemePreset(
    id: 'sakuraNoir',
    label: '樱桃暗场',
    primary: Color(0xFFD8577F),
    secondary: Color(0xFF8C7CF6),
    tertiary: Color(0xFFE7B95F),
    lightSurface: Color(0xFFFCF5F8),
    darkSurface: Color(0xFF1B0D13),
  ),
  KazumiThemePreset(
    id: 'auroraScreen',
    label: '银幕极光',
    primary: Color(0xFF8C7CF6),
    secondary: Color(0xFF00A7D8),
    tertiary: Color(0xFFE7B95F),
    lightSurface: Color(0xFFF7F5FC),
    darkSurface: Color(0xFF100E1D),
  ),
];
