import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:kazumi/pages/settings/danmaku/danmaku_shield_settings_sheet.dart';

class DanmakuSettingsSheet extends StatefulWidget {
  final DanmakuController danmakuController;
  final VoidCallback? onUpdateDanmakuSpeed;

  const DanmakuSettingsSheet({
    super.key,
    required this.danmakuController,
    this.onUpdateDanmakuSpeed,
  });

  @override
  State<DanmakuSettingsSheet> createState() => _DanmakuSettingsSheetState();
}

class _DanmakuSettingsSheetState extends State<DanmakuSettingsSheet> {
  Box setting = GStorage.setting;

  void showDanmakuShieldSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 3 / 4,
        maxWidth: (Utils.isDesktop() || Utils.isTablet())
            ? MediaQuery.of(context).size.width * 9 / 16
            : MediaQuery.of(context).size.width,
      ),
      clipBehavior: Clip.antiAlias,
      context: context,
      builder: (_) => const SafeArea(
        bottom: false,
        child: DanmakuShieldSettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: KazumiSpacing.md,
          vertical: KazumiSpacing.sm,
        ),
        children: [
          SettingsSectionCard(
            title: '弹幕屏蔽',
            icon: Icons.block_rounded,
            tiles: [
              SettingsNavTile(
                leading: const Icon(Icons.text_fields_rounded),
                title: '关键词屏蔽',
                onTap: showDanmakuShieldSheet,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: KazumiSpacing.md),
          SettingsSectionCard(
            title: '弹幕样式',
            icon: Icons.palette_rounded,
            tiles: [
              _danmakuSlider(
                icon: Icons.format_size_rounded,
                title: '字体大小',
                value: widget.danmakuController.option.fontSize,
                min: 10,
                max: Utils.isCompact() ? 32 : 48,
                label: '${widget.danmakuController.option.fontSize.floorToDouble()}',
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(
                      fontSize: v.floorToDouble(),
                    ),
                  );
                  setting.put(SettingBoxKey.danmakuFontSize, v.floorToDouble());
                  setState(() {});
                },
              ),
              _danmakuSlider(
                icon: Icons.opacity_rounded,
                title: '弹幕不透明度',
                value: widget.danmakuController.option.opacity,
                min: 0.1,
                max: 1,
                label: '${(widget.danmakuController.option.opacity * 100).round()}%',
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(opacity: v),
                  );
                  setting.put(SettingBoxKey.danmakuOpacity,
                      double.parse(v.toStringAsFixed(2)));
                  setState(() {});
                },
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: KazumiSpacing.md),
          SettingsSectionCard(
            title: '弹幕显示',
            icon: Icons.visibility_rounded,
            tiles: [
              _danmakuSlider(
                icon: Icons.fit_screen_rounded,
                title: '弹幕区域',
                value: widget.danmakuController.option.area,
                min: 0,
                max: 1,
                divisions: 8,
                label: '${(widget.danmakuController.option.area * 100).round()}%',
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(area: v),
                  );
                  setting.put(SettingBoxKey.danmakuArea, v);
                  setState(() {});
                },
              ),
              _danmakuSlider(
                icon: Icons.timelapse_rounded,
                title: '持续时间',
                value: widget.danmakuController.option.duration,
                min: 2,
                max: 16,
                divisions: 14,
                label: '${widget.danmakuController.option.duration.round()}',
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(duration: v),
                  );
                  setting.put(
                      SettingBoxKey.danmakuDuration, v.round().toDouble());
                  setState(() {});
                },
              ),
              _danmakuSlider(
                icon: Icons.height_rounded,
                title: '行高',
                value: widget.danmakuController.option.lineHeight,
                min: 0,
                max: 3,
                divisions: 30,
                label: widget.danmakuController.option.lineHeight.toStringAsFixed(1),
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(
                      lineHeight: double.parse(v.toStringAsFixed(1)),
                    ),
                  );
                  setting.put(SettingBoxKey.danmakuLineHeight,
                      double.parse(v.toStringAsFixed(1)));
                  setState(() {});
                },
              ),
              SettingsSwitchTile(
                leading: const Icon(Icons.vertical_align_top_rounded),
                title: '顶部弹幕',
                value: !widget.danmakuController.option.hideTop,
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(hideTop: !v),
                  );
                  setting.put(SettingBoxKey.danmakuTop, v);
                  setState(() {});
                },
              ),
              SettingsSwitchTile(
                leading: const Icon(Icons.vertical_align_bottom_rounded),
                title: '底部弹幕',
                value: !widget.danmakuController.option.hideBottom,
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(hideBottom: !v),
                  );
                  setting.put(SettingBoxKey.danmakuBottom, v);
                  setState(() {});
                },
              ),
              SettingsSwitchTile(
                leading: const Icon(Icons.scatter_plot_rounded),
                title: '滚动弹幕',
                value: !widget.danmakuController.option.hideScroll,
                onChanged: (v) {
                  widget.danmakuController.updateOption(
                    widget.danmakuController.option.copyWith(hideScroll: !v),
                  );
                  setting.put(SettingBoxKey.danmakuScroll, v);
                  setState(() {});
                },
              ),
              SettingsSwitchTile(
                leading: const Icon(Icons.speed_rounded),
                title: '跟随视频倍速',
                subtitle: '弹幕速度随视频倍速变化',
                value: setting.get(SettingBoxKey.danmakuFollowSpeed,
                    defaultValue: true),
                onChanged: (v) {
                  setting.put(SettingBoxKey.danmakuFollowSpeed, v);
                  widget.onUpdateDanmakuSpeed?.call();
                  setState(() {});
                },
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: KazumiSpacing.xl),
        ],
      ),
    );
  }

  Widget _danmakuSlider({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String label,
    required ValueChanged<double> onChanged,
    bool isLast = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: KazumiSpacing.lg),
          leading: Icon(icon, color: scheme.onSurfaceVariant, size: 22),
          title: Text(title,
              style: TextStyle(color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
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
          Divider(height: 1, indent: KazumiSpacing.lg + 22 + KazumiSpacing.md, endIndent: KazumiSpacing.lg, color: scheme.outlineVariant),
      ],
    );
  }
}
