import 'package:flutter/material.dart';
import 'package:kazumi/pages/settings/danmaku/danmaku_shield_settings.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DanmakuShieldSettingsSheet extends StatefulWidget {
  const DanmakuShieldSettingsSheet({super.key});

  @override
  State<DanmakuShieldSettingsSheet> createState() =>
      _DanmakuShieldSettingsSheetState();
}

class _DanmakuShieldSettingsSheetState
    extends State<DanmakuShieldSettingsSheet> {
  final MyController myController = Modular.get<MyController>();
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DanmakuShieldSettingsContent(
        myController: myController,
        textEditingController: textEditingController,
      ),
    );
  }
}
