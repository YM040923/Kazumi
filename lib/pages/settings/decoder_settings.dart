import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/constants.dart';

class DecoderSettings extends StatefulWidget {
  const DecoderSettings({super.key});

  @override
  State<DecoderSettings> createState() => _DecoderSettingsState();
}

class _DecoderSettingsState extends State<DecoderSettings> {
  late final Box setting = GStorage.setting;
  late String selected;

  @override
  void initState() {
    super.initState();
    selected =
        setting.get(SettingBoxKey.hardwareDecoder, defaultValue: 'auto-safe');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KazumiSettingsPageShell(
        title: '硬件解码器',
        subtitle: '选择播放器默认使用的硬件解码策略。',
        icon: Icons.developer_board_rounded,
        children: [
          SettingsSectionCard(
            title: '选择不受支持的解码器将回退到软件解码',
            icon: Icons.developer_board_rounded,
            tiles: [
              for (int i = 0; i < hardwareDecodersList.entries.length; i++)
                _RadioListTile(
                  title: hardwareDecodersList.entries.elementAt(i).key,
                  subtitle: hardwareDecodersList.entries.elementAt(i).value,
                  value: hardwareDecodersList.entries.elementAt(i).key,
                  groupValue: selected,
                  isLast: i == hardwareDecodersList.entries.length - 1,
                  onChanged: (v) {
                    setting.put(SettingBoxKey.hardwareDecoder, v);
                    setState(() => selected = v);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadioListTile extends StatelessWidget {
  const _RadioListTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value == groupValue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioListTile<String>(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: KazumiSpacing.lg),
          title: Text(title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
          subtitle: Text(subtitle,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              )),
          value: value,
          groupValue: groupValue,
          activeColor: scheme.primary,
          selected: selected,
          onChanged: (v) {
            if (v != null) onChanged(v);
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
  }
}
