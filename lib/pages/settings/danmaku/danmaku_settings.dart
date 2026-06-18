import 'package:kazumi/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';

class DanmakuSettingsPage extends StatefulWidget {
  const DanmakuSettingsPage({super.key});

  @override
  State<DanmakuSettingsPage> createState() => _DanmakuSettingsPageState();
}

class _DanmakuSettingsPageState extends State<DanmakuSettingsPage> {
  Box setting = GStorage.setting;
  late dynamic defaultDanmakuArea;
  late dynamic defaultDanmakuOpacity;
  late dynamic defaultDanmakuFontSize;
  late int defaultDanmakuFontWeight;
  late double defaultDanmakuDuration;
  late double defaultDanmakuLineHeight;
  late double defaultdanmakuBorderSize;
  final PopularController popularController = Modular.get<PopularController>();
  late bool danmakuBorder;
  late bool danmakuTop;
  late bool danmakuBottom;
  late bool danmakuScroll;
  late bool danmakuColor;
  late bool danmakuMassive;
  late bool danmakuDeduplication;
  late bool danmakuBiliBiliSource;
  late bool danmakuGamerSource;
  late bool danmakuDanDanSource;
  late bool danmakuFollowSpeed;

  @override
  void initState() {
    super.initState();
    defaultDanmakuArea =
        setting.get(SettingBoxKey.danmakuArea, defaultValue: 1.0);
    defaultDanmakuOpacity =
        setting.get(SettingBoxKey.danmakuOpacity, defaultValue: 1.0);
    defaultDanmakuFontSize = setting.get(SettingBoxKey.danmakuFontSize,
        defaultValue: (Utils.isCompact()) ? 16.0 : 25.0);
    defaultDanmakuFontWeight =
        setting.get(SettingBoxKey.danmakuFontWeight, defaultValue: 4);
    defaultDanmakuDuration =
        setting.get(SettingBoxKey.danmakuDuration, defaultValue: 8.0);
    defaultDanmakuLineHeight =
        setting.get(SettingBoxKey.danmakuLineHeight, defaultValue: 1.6);
    danmakuBorder =
        setting.get(SettingBoxKey.danmakuBorder, defaultValue: true);
    defaultdanmakuBorderSize =
        setting.get(SettingBoxKey.danmakuBorderSize, defaultValue: 1.5);
    danmakuTop = setting.get(SettingBoxKey.danmakuTop, defaultValue: true);
    danmakuBottom =
        setting.get(SettingBoxKey.danmakuBottom, defaultValue: false);
    danmakuScroll =
        setting.get(SettingBoxKey.danmakuScroll, defaultValue: true);
    danmakuColor = setting.get(SettingBoxKey.danmakuColor, defaultValue: true);
    danmakuMassive =
        setting.get(SettingBoxKey.danmakuMassive, defaultValue: false);
    danmakuDeduplication =
        setting.get(SettingBoxKey.danmakuDeduplication, defaultValue: false);
    danmakuBiliBiliSource =
        setting.get(SettingBoxKey.danmakuBiliBiliSource, defaultValue: true);
    danmakuGamerSource =
        setting.get(SettingBoxKey.danmakuGamerSource, defaultValue: true);
    danmakuDanDanSource =
        setting.get(SettingBoxKey.danmakuDanDanSource, defaultValue: true);
    danmakuFollowSpeed =
        setting.get(SettingBoxKey.danmakuFollowSpeed, defaultValue: true);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  void updateDanmakuArea(double i) async {
    await setting.put(SettingBoxKey.danmakuArea, i);
    setState(() {
      defaultDanmakuArea = i;
    });
  }

  void updateDanmakuOpacity(double i) async {
    await setting.put(SettingBoxKey.danmakuOpacity, i);
    setState(() {
      defaultDanmakuOpacity = i;
    });
  }

  void updateDanmakuFontSize(double i) async {
    await setting.put(SettingBoxKey.danmakuFontSize, i);
    setState(() {
      defaultDanmakuFontSize = i;
    });
  }

  void updateDanmakuDuration(double i) async {
    await setting.put(SettingBoxKey.danmakuDuration, i);
    setState(() {
      defaultDanmakuDuration = i;
    });
  }

  void updateDanmakuLineHeight(double i) async {
    await setting.put(SettingBoxKey.danmakuLineHeight, i);
    setState(() {
      defaultDanmakuLineHeight = i;
    });
  }

  void updateDanmakuFontWeight(int i) async {
    await setting.put(SettingBoxKey.danmakuFontWeight, i);
    setState(() {
      defaultDanmakuFontWeight = i;
    });
  }

  void updateDanmakuBorderSize(double i) async {
    await setting.put(SettingBoxKey.danmakuBorderSize, i);
    setState(() {
      defaultdanmakuBorderSize = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        onBackPressed(context);
      },
      child: Scaffold(
        body: KazumiSettingsPageShell(
          title: '弹幕设置',
          subtitle: '统一管理弹幕来源、屏蔽规则、显示区域和文字样式。',
          icon: Icons.subtitles_rounded,
          children: [
            SettingsSectionCard(
              title: '弹幕来源',
              icon: Icons.source_outlined,
              tiles: [
                SettingsSwitchTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: 'BiliBili',
                  value: danmakuBiliBiliSource,
                  onChanged: (value) async {
                    danmakuBiliBiliSource = value;
                    await setting.put(SettingBoxKey.danmakuBiliBiliSource,
                        danmakuBiliBiliSource);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.sports_esports),
                  title: 'Gamer',
                  value: danmakuGamerSource,
                  onChanged: (value) async {
                    danmakuGamerSource = value;
                    await setting.put(
                        SettingBoxKey.danmakuGamerSource, danmakuGamerSource);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.movie_outlined),
                  title: 'DanDan',
                  value: danmakuDanDanSource,
                  isLast: true,
                  onChanged: (value) async {
                    danmakuDanDanSource = value;
                    await setting.put(
                        SettingBoxKey.danmakuDanDanSource, danmakuDanDanSource);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.md),
            SettingsSectionCard(
              title: '弹幕屏蔽',
              icon: Icons.block_outlined,
              tiles: [
                SettingsNavTile(
                  leading: const Icon(Icons.key_outlined),
                  title: '关键词屏蔽',
                  isLast: true,
                  onTap: () {
                    Modular.to.pushNamed('/settings/danmaku/shield');
                  },
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.md),
            SettingsSectionCard(
              title: '弹幕显示',
              icon: Icons.tv_outlined,
              tiles: [
                _SliderTile(
                  leading: const Icon(Icons.aspect_ratio),
                  title: '弹幕区域',
                  value: defaultDanmakuArea,
                  min: 0,
                  max: 1,
                  divisions: 8,
                  label: '${(defaultDanmakuArea * 100).round()}%',
                  onChanged: (value) {
                    updateDanmakuArea(value);
                  },
                ),
                _SliderTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: '弹幕持续时间',
                  value: defaultDanmakuDuration,
                  min: 2,
                  max: 16,
                  divisions: 14,
                  label: '${defaultDanmakuDuration.round()}',
                  onChanged: (value) {
                    updateDanmakuDuration(value.round().toDouble());
                  },
                ),
                _SliderTile(
                  leading: const Icon(Icons.format_line_spacing),
                  title: '弹幕行高',
                  value: defaultDanmakuLineHeight,
                  min: 0,
                  max: 3,
                  divisions: 30,
                  label: defaultDanmakuLineHeight.toStringAsFixed(1),
                  onChanged: (value) {
                    updateDanmakuLineHeight(
                        double.parse(value.toStringAsFixed(1)));
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.speed),
                  title: '弹幕跟随视频倍速',
                  subtitle: '开启后弹幕速度会随视频倍速而改变',
                  value: danmakuFollowSpeed,
                  onChanged: (value) async {
                    danmakuFollowSpeed = value;
                    await setting.put(
                        SettingBoxKey.danmakuFollowSpeed, danmakuFollowSpeed);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.vertical_align_top),
                  title: '顶部弹幕',
                  value: danmakuTop,
                  onChanged: (value) async {
                    danmakuTop = value;
                    await setting.put(SettingBoxKey.danmakuTop, danmakuTop);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.vertical_align_bottom),
                  title: '底部弹幕',
                  value: danmakuBottom,
                  onChanged: (value) async {
                    danmakuBottom = value;
                    await setting.put(
                        SettingBoxKey.danmakuBottom, danmakuBottom);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.view_agenda),
                  title: '滚动弹幕',
                  value: danmakuScroll,
                  onChanged: (value) async {
                    danmakuScroll = value;
                    await setting.put(
                        SettingBoxKey.danmakuScroll, danmakuScroll);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.density_large),
                  title: '海量弹幕',
                  subtitle: '弹幕过多时进行叠加绘制',
                  value: danmakuMassive,
                  onChanged: (value) async {
                    danmakuMassive = value;
                    await setting.put(
                        SettingBoxKey.danmakuMassive, danmakuMassive);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.filter_list),
                  title: '弹幕去重',
                  subtitle: '相同内容弹幕过多时合并为一条弹幕',
                  value: danmakuDeduplication,
                  isLast: true,
                  onChanged: (value) async {
                    danmakuDeduplication = value;
                    await setting.put(SettingBoxKey.danmakuDeduplication,
                        danmakuDeduplication);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.md),
            SettingsSectionCard(
              title: '弹幕样式',
              icon: Icons.style_outlined,
              tiles: [
                SettingsSwitchTile(
                  leading: const Icon(Icons.border_style),
                  title: '弹幕描边',
                  value: danmakuBorder,
                  onChanged: (value) async {
                    danmakuBorder = value;
                    await setting.put(
                        SettingBoxKey.danmakuBorder, danmakuBorder);
                    setState(() {});
                  },
                ),
                _SliderTile(
                  leading: const Icon(Icons.line_weight),
                  title: '弹幕描边粗细',
                  value: defaultdanmakuBorderSize,
                  min: 0.1,
                  max: 3,
                  divisions: 29,
                  label: defaultdanmakuBorderSize.toStringAsFixed(1),
                  onChanged: (value) {
                    updateDanmakuBorderSize(
                        double.parse(value.toStringAsFixed(1)));
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: '弹幕颜色',
                  value: danmakuColor,
                  onChanged: (value) async {
                    danmakuColor = value;
                    await setting.put(SettingBoxKey.danmakuColor, danmakuColor);
                    setState(() {});
                  },
                ),
                _SliderTile(
                  leading: const Icon(Icons.format_size),
                  title: '字体大小',
                  value: defaultDanmakuFontSize,
                  min: 10,
                  max: Utils.isCompact() ? 32 : 48,
                  label: '${defaultDanmakuFontSize.floorToDouble()}',
                  onChanged: (value) {
                    updateDanmakuFontSize(value.floorToDouble());
                  },
                ),
                _SliderTile(
                  leading: const Icon(Icons.format_bold),
                  title: '字体字重',
                  value: defaultDanmakuFontWeight.toDouble(),
                  min: 1,
                  max: 9,
                  divisions: 8,
                  label: '$defaultDanmakuFontWeight',
                  onChanged: (value) {
                    updateDanmakuFontWeight(value.toInt());
                  },
                ),
                _SliderTile(
                  leading: const Icon(Icons.opacity),
                  title: '弹幕不透明度',
                  value: defaultDanmakuOpacity,
                  min: 0.1,
                  max: 1,
                  label: '${(defaultDanmakuOpacity * 100).round()}%',
                  isLast: true,
                  onChanged: (value) {
                    updateDanmakuOpacity(
                        double.parse(value.toStringAsFixed(2)));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A settings tile with a slider, matching the look of other settings tiles.
class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.leading,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    required this.onChanged,
    this.isLast = false,
  });

  final Widget leading;
  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
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
            vertical: 0,
          ),
          minVerticalPadding: 0,
          leading: IconTheme(
            data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
            child: leading,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
          subtitle: SizedBox(
            width: 200,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
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
