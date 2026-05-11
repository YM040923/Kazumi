import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/constants.dart';

class RendererSettings extends StatefulWidget {
  const RendererSettings({super.key});

  @override
  State<RendererSettings> createState() => _RendererSettingsState();
}

class _RendererSettingsState extends State<RendererSettings> {
  late final Box setting = GStorage.setting;
  late String selected;

  @override
  void initState() {
    super.initState();
    selected =
        setting.get(SettingBoxKey.androidVideoRenderer, defaultValue: 'auto');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = androidVideoRenderersList.entries.toList();

    return Scaffold(
      appBar: const SysAppBar(title: Text('视频渲染器')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: KazumiSpacing.md,
          vertical: KazumiSpacing.sm,
        ),
        children: [
          SettingsSectionCard(
            title: '选择合适的渲染器以获得最佳播放体验',
            icon: Icons.videocam_rounded,
            tiles: entries.map((e) {
              final isLast = entries.last.key == e.key;
              final isSelected = selected == e.key;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: KazumiSpacing.lg),
                    title: Text(e.key,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                    subtitle: Text(e.value,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        )),
                    value: e.key,
                    groupValue: selected,
                    activeColor: scheme.primary,
                    selected: isSelected,
                    onChanged: (v) {
                      if (v != null) {
                        setting.put(SettingBoxKey.androidVideoRenderer, v);
                        setState(() => selected = v);
                      }
                    },
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
            }).toList(),
          ),
        ],
      ),
    );
  }
}
