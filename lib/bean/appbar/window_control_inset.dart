import 'package:flutter/material.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/utils.dart';

class WindowControlMetrics {
  const WindowControlMetrics._();

  static const double buttonWidth = 46;
  static const double controlWidth = buttonWidth * 3;
  static const double controlHeight = 48;
}

class WindowControlInset extends StatelessWidget {
  const WindowControlInset({
    super.key,
    required this.child,
  });

  final Widget child;

  bool get _showWindowButton {
    return GStorage.setting
        .get(SettingBoxKey.showWindowButton, defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    final showControls = Utils.isDesktop() && !_showWindowButton;
    return Padding(
      padding: EdgeInsets.only(
        right: showControls ? WindowControlMetrics.controlWidth : 0,
      ),
      child: child,
    );
  }
}

class WindowControlTopActionArea extends StatelessWidget {
  const WindowControlTopActionArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WindowControlMetrics.controlHeight,
      child: Center(child: child),
    );
  }
}
