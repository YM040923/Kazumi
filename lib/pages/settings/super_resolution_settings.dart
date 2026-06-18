import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';

class SuperResolutionSettings extends StatefulWidget {
  const SuperResolutionSettings({super.key});

  @override
  State<SuperResolutionSettings> createState() =>
      _SuperResolutionSettingsState();
}

class _SuperResolutionSettingsState extends State<SuperResolutionSettings> {
  late final Box setting = GStorage.setting;
  late bool promptOnEnable;
  late String selected;

  @override
  void initState() {
    super.initState();
    promptOnEnable =
        setting.get(SettingBoxKey.superResolutionWarn, defaultValue: false);
    selected = setting
        .get(SettingBoxKey.defaultSuperResolutionType, defaultValue: 1)
        .toString();
  }

  static const _options = [
    ('OFF', '默认禁用超分辨率', '1'),
    ('Efficiency', '默认启用基于Anime4K的超分辨率 (效率优先)', '2'),
    ('Quality', '默认启用基于Anime4K的超分辨率 (质量优先)', '3'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: KazumiSettingsPageShell(
        title: '超分辨率',
        subtitle: '配置 Anime4K 超分策略和启用提示。',
        icon: Icons.hd_rounded,
        children: [
          SettingsSectionCard(
            title: '超分辨率需要启用硬件解码，若启用后仍不生效，尝试切换渲染器为 gpu',
            icon: Icons.hd_rounded,
            tiles: _options.map((o) {
              final isLast = _options.last.$3 == o.$3;
              final isSelected = selected == o.$3;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: KazumiSpacing.lg),
                    title: Text(o.$1,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                    subtitle: Text(o.$2,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        )),
                    value: o.$3,
                    groupValue: selected,
                    activeColor: scheme.primary,
                    selected: isSelected,
                    onChanged: (v) {
                      if (v != null) {
                        setting.put(SettingBoxKey.defaultSuperResolutionType,
                            int.tryParse(v) ?? 1);
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
          const SizedBox(height: KazumiSpacing.md),
          SettingsSectionCard(
            title: '默认行为',
            icon: Icons.tune_rounded,
            tiles: [
              SettingsSwitchTile(
                leading: const Icon(Icons.notifications_off_rounded),
                title: '关闭提示',
                subtitle: '关闭每次启用超分辨率时的提示',
                value: promptOnEnable,
                onChanged: (v) async {
                  promptOnEnable = v;
                  await setting.put(
                      SettingBoxKey.superResolutionWarn, promptOnEnable);
                  if (mounted) setState(() {});
                },
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
