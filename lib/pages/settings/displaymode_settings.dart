import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';

class SetDisplayMode extends StatefulWidget {
  const SetDisplayMode({super.key});

  @override
  State<SetDisplayMode> createState() => _SetDisplayModeState();
}

class _SetDisplayModeState extends State<SetDisplayMode> {
  List<DisplayMode> modes = <DisplayMode>[];
  DisplayMode? active;
  DisplayMode? preferred;
  Box setting = GStorage.setting;

  final ValueNotifier<int> page = ValueNotifier<int>(0);
  late final PageController controller = PageController()
    ..addListener(() {
      page.value = controller.page!.round();
    });

  @override
  void initState() {
    super.initState();
    init();
    SchedulerBinding.instance.addPostFrameCallback((_) => fetchAll());
  }

  Future<void> fetchAll() async {
    preferred = await FlutterDisplayMode.preferred;
    active = await FlutterDisplayMode.active;
    await setting.put(SettingBoxKey.displayMode, preferred.toString());
    setState(() {});
  }

  Future<void> init() async {
    try {
      modes = await FlutterDisplayMode.supported;
    } on PlatformException catch (_) {}
    preferred = modes.firstWhere(
      (el) => el == getDisplayModeType(),
      orElse: () => DisplayMode.auto,
    );
    FlutterDisplayMode.setPreferredMode(preferred!);
  }

  DisplayMode getDisplayModeType() {
    final value = setting.get(SettingBoxKey.displayMode);
    if (value != null) {
      return modes.firstWhere((e) => e.toString() == value);
    }
    return DisplayMode.auto;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('屏幕帧率设置')),
      body: modes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: KazumiSpacing.md,
                vertical: KazumiSpacing.sm,
              ),
              children: [
                SettingsSectionCard(
                  title: '没有生效? 重启app试试',
                  icon: Icons.screenshot_monitor_rounded,
                  tiles: modes.map((e) {
                    final isLast = modes.last == e;
                    final isSelected = e == preferred;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<DisplayMode>(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: KazumiSpacing.lg),
                          title: Text(
                            e == DisplayMode.auto
                                ? '自动'
                                : '$e${e == active ? "  [系统]" : ""}',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: e,
                          groupValue: preferred,
                          activeColor: scheme.primary,
                          selected: isSelected,
                          onChanged: (newMode) async {
                            await FlutterDisplayMode.setPreferredMode(newMode!);
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            await fetchAll();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: isLast
                                ? BorderRadius.only(
                                    bottomLeft:
                                        Radius.circular(KazumiRadius.md),
                                    bottomRight:
                                        Radius.circular(KazumiRadius.md),
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
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
