import 'package:flutter/material.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';

/// 设置区块卡片 - 包含标题和图标的 M3 Card
///
/// 用于替换 card_settings_ui 的 SettingsSection，
/// 提供统一的设置区块样式。
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.tiles,
  });

  final String title;
  final IconData icon;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KazumiGlassSurface(
      borderRadius: KazumiRadius.cardBorder,
      blurSigma: 14,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.64 : 0.76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KazumiSpacing.lg,
              KazumiSpacing.md,
              KazumiSpacing.lg,
              KazumiSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: KazumiSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...tiles,
        ],
      ),
    );
  }
}

/// 设置项 - 基于 M3 ListTile 的导航项
///
/// 用于替换 card_settings_ui 的 SettingsTile.navigation，
/// 自动继承主题样式，无需手动传 fontFamily。
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isLast = false,
    this.trailing,
    this.contentPadding,
    this.minVerticalPadding,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;
  final Widget? trailing;
  final EdgeInsetsGeometry? contentPadding;
  final double? minVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: KazumiSpacing.lg,
                vertical: 0,
              ),
          minVerticalPadding: minVerticalPadding ?? 0,
          leading: IconTheme(
            data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
            child: leading,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: isLast
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(KazumiRadius.md),
                    bottomRight: Radius.circular(KazumiRadius.md),
                  )
                : BorderRadius.zero,
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: KazumiSpacing.lg + 22 + KazumiSpacing.md,
            endIndent: KazumiSpacing.lg,
            color: scheme.outlineVariant,
          ),
      ],
    );
  }
}

/// 设置开关项 - 带 Switch 的 ListTile
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          secondary: IconTheme(
            data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
            child: leading,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
          value: value,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.lg,
            vertical: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: isLast
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(KazumiRadius.md),
                    bottomRight: Radius.circular(KazumiRadius.md),
                  )
                : BorderRadius.zero,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: KazumiSpacing.lg + 22 + KazumiSpacing.md,
            endIndent: KazumiSpacing.lg,
            color: scheme.outlineVariant,
          ),
      ],
    );
  }
}
