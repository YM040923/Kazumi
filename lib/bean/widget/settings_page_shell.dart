import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';

class KazumiSettingsPageShell extends StatelessWidget {
  const KazumiSettingsPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.actions,
    this.onBack,
    this.maxWidth = KazumiDesktopShell.mediaPageMaxWidth,
    this.bottomPadding = KazumiSpacing.xl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget? actions;
  final VoidCallback? onBack;
  final double maxWidth;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return KazumiDesktopScrollFrame(
      maxWidth: maxWidth,
      bottomPadding: bottomPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KazumiSettingsPageHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            actions: actions,
            onBack: onBack,
          ),
          const SizedBox(height: KazumiSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class KazumiSettingsPageHeader extends StatelessWidget {
  const KazumiSettingsPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: dtb.DragToMoveArea(
        child: KazumiGlassSurface(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: KazumiDesktopHeaderTopRow(
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: onBack ?? () => Modular.to.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: '返回',
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(width: 16),
                  actions!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
