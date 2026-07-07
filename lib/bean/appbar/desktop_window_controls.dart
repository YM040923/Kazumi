import 'package:flutter/material.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:window_manager/window_manager.dart';

class WindowControlMetrics {
  const WindowControlMetrics._();

  static const double buttonWidth = 46;
  static const double controlHeight = 48;
  static const double controlWidth = buttonWidth * 3;
}

class DesktopWindowButtonMode {
  DesktopWindowButtonMode._();

  static final ValueNotifier<bool> showNativeButtons = ValueNotifier<bool>(
    GStorage.setting.get(SettingBoxKey.showWindowButton, defaultValue: false),
  );

  static void syncFromStorage() {
    showNativeButtons.value = GStorage.setting
        .get(SettingBoxKey.showWindowButton, defaultValue: false);
  }

  static void setShowNativeButtons(bool value) {
    showNativeButtons.value = value;
  }
}

class DesktopWindowActionRail extends StatelessWidget {
  const DesktopWindowActionRail({
    super.key,
    this.actions = const [],
    this.trailingSpacing = 0,
  });

  final List<Widget> actions;
  final double trailingSpacing;

  @override
  Widget build(BuildContext context) {
    DesktopWindowButtonMode.syncFromStorage();
    return ValueListenableBuilder<bool>(
      valueListenable: DesktopWindowButtonMode.showNativeButtons,
      builder: (context, showNativeButtons, _) {
        final showCustomControls = Utils.isDesktop() && !showNativeButtons;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...actions,
            if (showCustomControls)
              const DesktopWindowControls(trailingSpacing: 0),
            if (trailingSpacing > 0) SizedBox(width: trailingSpacing),
          ],
        );
      },
    );
  }
}

class DesktopWindowControls extends StatelessWidget {
  const DesktopWindowControls({
    super.key,
    this.trailingSpacing = 8,
  });

  final double trailingSpacing;

  Future<void> _toggleMaximizeWindow() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
      return;
    }
    await windowManager.maximize();
  }

  @override
  Widget build(BuildContext context) {
    if (!Utils.isDesktop()) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _windowButton(
          context: context,
          tooltip: '最小化',
          onPressed: () => windowManager.minimize(),
          icon: const _CenteredMinimizeIcon(),
        ),
        _windowButton(
          context: context,
          tooltip: '最大化/还原',
          onPressed: _toggleMaximizeWindow,
          icon: const Icon(Icons.crop_square_rounded),
        ),
        _windowButton(
          context: context,
          tooltip: '关闭',
          onPressed: () => windowManager.close(),
          icon: const Icon(Icons.close_rounded),
          isClose: true,
        ),
        if (trailingSpacing > 0) SizedBox(width: trailingSpacing),
      ],
    );
  }

  Widget _windowButton({
    required BuildContext context,
    required String tooltip,
    required VoidCallback onPressed,
    required Widget icon,
    bool isClose = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(
        width: WindowControlMetrics.buttonWidth,
        height: WindowControlMetrics.controlHeight,
      ),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        hoverColor: isClose
            ? Colors.red.withValues(alpha: 0.12)
            : colorScheme.onSurface.withValues(alpha: 0.08),
        highlightColor: isClose
            ? Colors.red.withValues(alpha: 0.18)
            : colorScheme.onSurface.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: icon,
    );
  }
}

class DesktopWindowControlsOverlay extends StatelessWidget {
  const DesktopWindowControlsOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Utils.isDesktop()) {
      return child;
    }

    DesktopWindowButtonMode.syncFromStorage();
    return ValueListenableBuilder<bool>(
      valueListenable: DesktopWindowButtonMode.showNativeButtons,
      builder: (context, showNativeButtons, _) {
        return Stack(
          children: [
            child,
            if (!showNativeButtons)
              const Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  left: false,
                  child: SizedBox(
                    width: WindowControlMetrics.controlWidth,
                    height: WindowControlMetrics.controlHeight,
                    child: _OverlayWindowControls(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OverlayWindowControls extends StatelessWidget {
  const _OverlayWindowControls();

  Future<void> _toggleMaximizeWindow() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
      return;
    }
    await windowManager.maximize();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _windowButton(
          context: context,
          onPressed: () => windowManager.minimize(),
          icon: const _CenteredMinimizeIcon(),
        ),
        _windowButton(
          context: context,
          onPressed: _toggleMaximizeWindow,
          icon: const Icon(Icons.crop_square_rounded),
        ),
        _windowButton(
          context: context,
          onPressed: () => windowManager.close(),
          icon: const Icon(Icons.close_rounded),
          isClose: true,
        ),
      ],
    );
  }

  Widget _windowButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget icon,
    bool isClose = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      constraints: const BoxConstraints.tightFor(
        width: WindowControlMetrics.buttonWidth,
        height: WindowControlMetrics.controlHeight,
      ),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        hoverColor: isClose
            ? Colors.red.withValues(alpha: 0.12)
            : colorScheme.onSurface.withValues(alpha: 0.08),
        highlightColor: isClose
            ? Colors.red.withValues(alpha: 0.18)
            : colorScheme.onSurface.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: icon,
    );
  }
}

class _CenteredMinimizeIcon extends StatelessWidget {
  const _CenteredMinimizeIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
