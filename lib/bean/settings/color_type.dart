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
    final id = stored.startsWith(prefix) ? stored.substring(prefix.length) : stored;
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
    id: 'amberTheater',
    label: '剧院琥珀',
    primary: Color(0xFFC97833),
    secondary: Color(0xFF7C5A2C),
    tertiary: Color(0xFFB84A62),
    lightSurface: Color(0xFFFBF7F1),
    darkSurface: Color(0xFF17110D),
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
    label: '胶片青绿',
    primary: Color(0xFF1F8A7A),
    secondary: Color(0xFF3D6FB6),
    tertiary: Color(0xFFC97833),
    lightSurface: Color(0xFFF2FAF8),
    darkSurface: Color(0xFF071716),
  ),
  KazumiThemePreset(
    id: 'violetNight',
    label: '夜幕紫罗兰',
    primary: Color(0xFF7A5BB8),
    secondary: Color(0xFF3D6FB6),
    tertiary: Color(0xFFB84A62),
    lightSurface: Color(0xFFF8F5FB),
    darkSurface: Color(0xFF120F1B),
  ),
  KazumiThemePreset(
    id: 'sakuraScreening',
    label: '樱桃放映',
    primary: Color(0xFFB84A62),
    secondary: Color(0xFFC97833),
    tertiary: Color(0xFF7A5BB8),
    lightSurface: Color(0xFFFCF5F7),
    darkSurface: Color(0xFF1A0E12),
  ),
  KazumiThemePreset(
    id: 'indigoScreen',
    label: '银幕靛蓝',
    primary: Color(0xFF53668F),
    secondary: Color(0xFF3D6FB6),
    tertiary: Color(0xFF1F8A7A),
    lightSurface: Color(0xFFF4F6FA),
    darkSurface: Color(0xFF0E1219),
  ),
];
