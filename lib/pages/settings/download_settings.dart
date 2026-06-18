import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';

class DownloadSettingsPage extends StatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  State<DownloadSettingsPage> createState() => _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends State<DownloadSettingsPage> {
  Box setting = GStorage.setting;
  late int parallelEpisodes;
  late int parallelSegments;
  late bool downloadDanmaku;

  @override
  void initState() {
    super.initState();
    parallelEpisodes =
        setting.get(SettingBoxKey.downloadParallelEpisodes, defaultValue: 2);
    parallelSegments =
        setting.get(SettingBoxKey.downloadParallelSegments, defaultValue: 3);
    downloadDanmaku =
        setting.get(SettingBoxKey.downloadDanmaku, defaultValue: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KazumiSettingsPageShell(
        title: '下载设置',
        subtitle: '调整缓存并发、分片数量和弹幕缓存行为。',
        icon: Icons.download_for_offline_rounded,
        children: [
          SettingsSectionCard(
            title: '并发设置',
            icon: Icons.speed_rounded,
            tiles: [
              _SliderTile(
                icon: Icons.queue_play_next_rounded,
                title: '同时下载集数',
                subtitle: '同时下载 $parallelEpisodes 集',
                value: parallelEpisodes.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) {
                  parallelEpisodes = v.toInt();
                  setting.put(
                      SettingBoxKey.downloadParallelEpisodes, parallelEpisodes);
                  setState(() {});
                },
              ),
              _SliderTile(
                icon: Icons.dashboard_rounded,
                title: '分片并发数',
                subtitle: '每集同时下载 $parallelSegments 个分片',
                value: parallelSegments.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) {
                  parallelSegments = v.toInt();
                  setting.put(
                      SettingBoxKey.downloadParallelSegments, parallelSegments);
                  setState(() {});
                },
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: KazumiSpacing.md),
          SettingsSectionCard(
            title: '缓存设置',
            icon: Icons.save_alt_rounded,
            tiles: [
              SettingsSwitchTile(
                leading: const Icon(Icons.subtitles_rounded),
                title: '缓存弹幕',
                subtitle: '下载视频时同时缓存弹幕数据',
                value: downloadDanmaku,
                onChanged: (v) {
                  downloadDanmaku = v;
                  setting.put(SettingBoxKey.downloadDanmaku, downloadDanmaku);
                  setState(() {});
                },
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: KazumiSpacing.md),
          SettingsSectionCard(
            title: '说明',
            icon: Icons.info_outline_rounded,
            tiles: [
              SettingsNavTile(
                leading: const Icon(Icons.message_rounded),
                title: '关于并发设置',
                subtitle: '集数并发：同时下载多少集视频\n'
                    '分片并发：每集内同时下载多少个视频片段\n'
                    '较高的并发可提升速度，但可能被服务器限制\n'
                    '修改后对新开始的下载生效',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.lg,
          ),
          leading: Icon(icon, color: scheme.onSurfaceVariant, size: 22),
          title: Text(title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: KazumiSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    )),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: value.toInt().toString(),
                  onChanged: onChanged,
                ),
              ],
            ),
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
