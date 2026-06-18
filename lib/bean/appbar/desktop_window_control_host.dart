import 'package:flutter/material.dart';
import 'package:kazumi/bean/appbar/desktop_window_controls.dart';
import 'package:kazumi/bean/widget/embedded_native_control_area.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/utils.dart';

class DesktopWindowControlHost extends StatelessWidget {
  const DesktopWindowControlHost({
    super.key,
    required this.child,
    this.top = 0,
    this.controlTop,
  });

  static const double controlReservedWidth = 152;

  final Widget child;
  final double top;
  final double? controlTop;

  bool get _showWindowButton {
    return GStorage.setting
        .get(SettingBoxKey.showWindowButton, defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    final showControls = Utils.isDesktop() && !_showWindowButton;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            right: showControls ? controlReservedWidth : 0,
          ),
          child: child,
        ),
        if (showControls)
          Positioned(
            top: controlTop ?? top,
            right: 0,
            child: const EmbeddedNativeControlArea(
              child: DesktopWindowControls(trailingSpacing: 0),
            ),
          ),
      ],
    );
  }
}

