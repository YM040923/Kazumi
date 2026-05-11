import 'package:flutter/material.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/constants.dart';

/// Kazumi 主题工厂 - 基于 Material 3 的深度主题定制
///
/// 生成完整的 ThemeData，包含所有 M3 组件主题的精细化配置。
class KazumiTheme {
  KazumiTheme._();

  /// 构建优化后的 App 主题
  static ThemeData buildTheme({
    required Brightness brightness,
    required String? fontFamily,
    Color? colorSeed,
    ColorScheme? colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: brightness,
      colorSchemeSeed: colorSeed,
      colorScheme: colorScheme,
      progressIndicatorTheme: progressIndicatorTheme2024,
      sliderTheme: sliderTheme2024,
      pageTransitionsTheme: pageTransitionsTheme2024,
    );

    final scheme = colorScheme ?? _schemeFromSeed(colorSeed, brightness);

    return base.copyWith(
      // ========== 基础组件主题 ==========
      cardTheme: _cardTheme(scheme, isDark),
      appBarTheme: _appBarTheme(scheme),
      navigationBarTheme: _navBarTheme(scheme),
      navigationRailTheme: _navRailTheme(scheme),
      floatingActionButtonTheme: _fabTheme(scheme),
      iconButtonTheme: _iconButtonTheme(scheme),
      listTileTheme: _listTileTheme(scheme),
      chipTheme: _chipTheme(scheme, isDark),
      tabBarTheme: _tabBarTheme(scheme),
      dialogTheme: _dialogTheme(scheme),
      bottomSheetTheme: _bottomSheetTheme(scheme),
      inputDecorationTheme: _inputDecorationTheme(scheme, isDark),
      dividerTheme: _dividerTheme(scheme),
      badgeTheme: _badgeTheme(scheme),

      // ========== 色彩方案微调 ==========
      colorScheme: scheme.copyWith(
        // 设置页面内容区域色
        surfaceContainerLowest: isDark
            ? const Color(0xFF0D0D0D)
            : const Color(0xFFF8F8F8),
        surfaceContainerLow: isDark
            ? const Color(0xFF141414)
            : const Color(0xFFF3F3F3),
        surfaceContainer: isDark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFEEEEEE),
      ),

      // ========== 文本主题 ==========
      textTheme: _buildTextTheme(base.textTheme, scheme, isDark),
    );
  }

  /// 如果没有现成的 colorScheme，从 seed 生成
  static ColorScheme _schemeFromSeed(
      Color? colorSeed, Brightness brightness) {
    final seed = colorSeed ?? Colors.green;
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
  }

  // ========== 卡片主题 ==========
  static CardThemeData _cardTheme(ColorScheme scheme, bool isDark) {
    return CardThemeData(
      elevation: KazumiElevations.subtle,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: KazumiRadius.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: isDark ? scheme.surfaceContainerLow : scheme.surface,
    );
  }

  // ========== AppBar 主题 ==========
  static AppBarTheme _appBarTheme(ColorScheme scheme) {
    return AppBarTheme(
      elevation: KazumiElevations.none,
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: KazumiElevations.subtle,
      titleSpacing: KazumiSpacing.lg,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    );
  }

  // ========== 底部导航栏主题 ==========
  static NavigationBarThemeData _navBarTheme(ColorScheme scheme) {
    return NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.lg),
      ),
      surfaceTintColor: Colors.transparent,
      elevation: KazumiElevations.subtle,
      shadowColor: Colors.black26,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: scheme.onSecondaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          );
        }
        return TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: scheme.onSecondaryContainer,
            size: 24,
          );
        }
        return IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 24,
        );
      }),
    );
  }

  // ========== 侧边导航栏主题 ==========
  static NavigationRailThemeData _navRailTheme(ColorScheme scheme) {
    return NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      elevation: KazumiElevations.none,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.lg),
      ),
      selectedIconTheme: IconThemeData(
        color: scheme.onSecondaryContainer,
        size: 22,
      ),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: 22,
      ),
      selectedLabelTextStyle: TextStyle(
        color: scheme.onSecondaryContainer,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      labelType: NavigationRailLabelType.selected,
      groupAlignment: 1.0,
    );
  }

  // ========== FAB 主题 ==========
  static FloatingActionButtonThemeData _fabTheme(ColorScheme scheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      elevation: KazumiElevations.low,
      hoverElevation: KazumiElevations.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.lg),
      ),
      extendedTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.2,
      ),
      extendedIconLabelSpacing: 8,
    );
  }

  // ========== IconButton 主题 ==========
  static IconButtonThemeData _iconButtonTheme(ColorScheme scheme) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        hoverColor: scheme.onSurfaceVariant.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KazumiRadius.sm),
        ),
      ),
    );
  }

  // ========== ListTile 主题 ==========
  static ListTileThemeData _listTileTheme(ColorScheme scheme) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KazumiSpacing.lg,
        vertical: KazumiSpacing.xs,
      ),
      minLeadingWidth: 24,
      horizontalTitleGap: KazumiSpacing.md,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.md),
      ),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 13,
      ),
      leadingAndTrailingTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 13,
      ),
      iconColor: scheme.onSurfaceVariant,
    );
  }

  // ========== Chip 主题 ==========
  static ChipThemeData _chipTheme(ColorScheme scheme, bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.sm),
      ),
      side: BorderSide.none,
      elevation: KazumiElevations.none,
    );
  }

  // ========== TabBar 主题 ==========
  static TabBarThemeData _tabBarTheme(ColorScheme scheme) {
    return TabBarThemeData(
      indicatorColor: scheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      dividerHeight: 0,
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      tabAlignment: TabAlignment.start,
    );
  }

  // ========== Dialog 主题 ==========
  static DialogThemeData _dialogTheme(ColorScheme scheme) {
    return DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.xl),
      ),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      elevation: KazumiElevations.high,
    );
  }

  // ========== BottomSheet 主题 ==========
  static BottomSheetThemeData _bottomSheetTheme(ColorScheme scheme) {
    return BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KazumiRadius.xl),
        ),
      ),
      elevation: KazumiElevations.standard,
      modalElevation: KazumiElevations.high,
    );
  }

  // ========== InputDecoration 主题 ==========
  static InputDecorationTheme _inputDecorationTheme(
      ColorScheme scheme, bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KazumiSpacing.lg,
        vertical: KazumiSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KazumiRadius.md),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 14,
      ),
    );
  }

  // ========== Divider 主题 ==========
  static DividerThemeData _dividerTheme(ColorScheme scheme) {
    return DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 0.5,
      space: 0,
    );
  }

  // ========== Badge 主题 ==========
  static BadgeThemeData _badgeTheme(ColorScheme scheme) {
    return BadgeThemeData(
      backgroundColor: scheme.error,
      textColor: scheme.onError,
      textStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ========== 文本主题 ==========
  static TextTheme _buildTextTheme(
      TextTheme base, ColorScheme scheme, bool isDark) {
    return base.copyWith(
      // 大标题
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),

      // 标题
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),

      // 正文
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
        height: 1.4,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
        height: 1.3,
      ),

      // 标签
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: scheme.onSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
