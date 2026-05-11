import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/pip_utils.dart';
import 'package:kazumi/utils/utils.dart';

class PlayerSettingsPage extends StatefulWidget {
  const PlayerSettingsPage({super.key});

  @override
  State<PlayerSettingsPage> createState() => _PlayerSettingsPageState();
}

class _PlayerSettingsPageState extends State<PlayerSettingsPage> {
  Box setting = GStorage.setting;
  late double defaultPlaySpeed;
  late double defaultShortcutForwardPlaySpeed;
  late int defaultAspectRatioType;
  late bool hAenable;
  late bool androidEnableOpenSLES;
  late bool androidAutoEnterPIP;
  late bool lowMemoryMode;
  late bool playResume;
  late bool showPlayerError;
  late bool privateMode;
  late bool playerDebugMode;
  late bool playerDisableAnimations;
  late bool forceAdBlocker;
  late bool autoPlayNext;
  late bool backgroundPlayback;
  late bool brightnessVolumeGesture;
  late int playerButtonSkipTime;
  late int playerArrowKeySkipTime;
  late int playerLogLevel;
  final MenuController playerAspectRatioMenuController = MenuController();
  final MenuController playerLogLevelMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    defaultPlaySpeed =
        setting.get(SettingBoxKey.defaultPlaySpeed, defaultValue: 1.0);
    defaultShortcutForwardPlaySpeed =
        setting.get(SettingBoxKey.defaultShortcutForwardPlaySpeed,
            defaultValue: 2.0);
    defaultAspectRatioType =
        setting.get(SettingBoxKey.defaultAspectRatioType, defaultValue: 1);
    hAenable = setting.get(SettingBoxKey.hAenable, defaultValue: true);
    androidEnableOpenSLES =
        setting.get(SettingBoxKey.androidEnableOpenSLES, defaultValue: true);
    androidAutoEnterPIP =
        setting.get(SettingBoxKey.androidAutoEnterPIP, defaultValue: false);
    lowMemoryMode =
        setting.get(SettingBoxKey.lowMemoryMode, defaultValue: false);
    playResume = setting.get(SettingBoxKey.playResume, defaultValue: true);
    privateMode = setting.get(SettingBoxKey.privateMode, defaultValue: false);
    showPlayerError =
        setting.get(SettingBoxKey.showPlayerError, defaultValue: true);
    playerDebugMode =
        setting.get(SettingBoxKey.playerDebugMode, defaultValue: false);
    autoPlayNext = setting.get(SettingBoxKey.autoPlayNext, defaultValue: true);
    backgroundPlayback =
        setting.get(SettingBoxKey.backgroundPlayback, defaultValue: false);
    playerDisableAnimations = setting
        .get(SettingBoxKey.playerDisableAnimations, defaultValue: false);
    forceAdBlocker =
        setting.get(SettingBoxKey.forceAdBlocker, defaultValue: false);
    playerLogLevel =
        setting.get(SettingBoxKey.playerLogLevel, defaultValue: 2);
    brightnessVolumeGesture =
        setting.get(SettingBoxKey.brightnessVolumeGesture, defaultValue: true);
    playerButtonSkipTime =
        setting.get(SettingBoxKey.buttonSkipTime, defaultValue: 80);
    playerArrowKeySkipTime =
        setting.get(SettingBoxKey.arrowKeySkipTime, defaultValue: 10);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
    }
  }

  Future<void> updateButtonSkipTime() async {
    final int? newButtonSkipTime = await _showSkipTimeChangeDialog(
        title: '顶部按钮快进时长',
        initialValue: playerButtonSkipTime.toString());
    if (newButtonSkipTime != null &&
        newButtonSkipTime != playerButtonSkipTime) {
      setting.put(SettingBoxKey.buttonSkipTime, newButtonSkipTime);
      setState(() => playerButtonSkipTime = newButtonSkipTime);
    }
  }

  Future<int?> _showSkipTimeChangeDialog({
    required String title,
    required String initialValue,
  }) async {
    return KazumiDialog.show<int>(builder: (context) {
      String input = "";
      return AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return TextField(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.never,
                labelText: initialValue,
              ),
              onChanged: (value) => input = value,
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => KazumiDialog.dismiss(),
            child: Text('取消',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.outline)),
          ),
          TextButton(
            onPressed: () {
              final int? newValue = int.tryParse(input);
              if (newValue == null) {
                KazumiDialog.showToast(message: '请输入数字');
                return;
              }
              if (newValue <= 0) {
                KazumiDialog.showToast(message: '请输入大于0的数字');
                return;
              }
              KazumiDialog.dismiss(popWith: newValue);
            },
            child: const Text('确定'),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) => onBackPressed(context),
      child: Scaffold(
        appBar: const SysAppBar(title: Text('播放设置')),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.md,
            vertical: KazumiSpacing.sm,
          ),
          children: [
            // 解码与渲染
            SettingsSectionCard(
              title: '解码与渲染',
              icon: Icons.memory_rounded,
              tiles: _buildDecoderTiles(),
            ),
            const SizedBox(height: KazumiSpacing.md),
            // 播放行为
            SettingsSectionCard(
              title: '播放行为',
              icon: Icons.play_circle_outline_rounded,
              tiles: _buildBehaviorTiles(),
            ),
            const SizedBox(height: KazumiSpacing.md),
            // 调试与开发
            SettingsSectionCard(
              title: '调试与开发',
              icon: Icons.bug_report_outlined,
              tiles: _buildDebugTiles(),
            ),
            const SizedBox(height: KazumiSpacing.md),
            // 播放参数
            SettingsSectionCard(
              title: '播放参数',
              icon: Icons.tune_rounded,
              tiles: [
                _sliderTile(
                  icon: Icons.speed_rounded,
                  title: '默认倍速',
                  value: defaultPlaySpeed,
                  min: 0.25,
                  max: 3,
                  divisions: 11,
                  label: '${defaultPlaySpeed}x',
                  onChanged: (v) {
                    final speed = double.parse(v.toStringAsFixed(2));
                    setting.put(SettingBoxKey.defaultPlaySpeed, speed);
                    setState(() => defaultPlaySpeed = speed);
                  },
                ),
                _sliderTile(
                  icon: Icons.fast_forward_rounded,
                  title: '默认方向键倍速',
                  value: defaultShortcutForwardPlaySpeed,
                  min: 1.25,
                  max: 3,
                  divisions: 7,
                  label: '${defaultShortcutForwardPlaySpeed}x',
                  onChanged: (v) {
                    final speed = double.parse(v.toStringAsFixed(2));
                    setting.put(
                        SettingBoxKey.defaultShortcutForwardPlaySpeed, speed);
                    setState(() => defaultShortcutForwardPlaySpeed = speed);
                  },
                ),
                _sliderTile(
                  icon: Icons.keyboard_double_arrow_left_rounded,
                  title: '方向键快进/快退秒数',
                  value: playerArrowKeySkipTime.toDouble(),
                  min: 0,
                  max: 15,
                  divisions: 15,
                  label: '$playerArrowKeySkipTime秒',
                  onChanged: (v) {
                    final secs = v.toInt();
                    setting.put(SettingBoxKey.arrowKeySkipTime, secs);
                    setState(() => playerArrowKeySkipTime = secs);
                  },
                ),
                SettingsNavTile(
                  leading: const Icon(Icons.skip_next_rounded),
                  title: '跳过时长',
                  subtitle: '顶栏跳过按钮的秒数',
                  trailing: Text('$playerButtonSkipTime 秒',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 13)),
                  onTap: updateButtonSkipTime,
                ),
                SettingsNavTile(
                  leading: const Icon(Icons.aspect_ratio_rounded),
                  title: '默认视频比例',
                  subtitle: aspectRatioTypeMap[defaultAspectRatioType] ?? '自动',
                  trailing: MenuAnchor(
                    consumeOutsideTap: true,
                    controller: playerAspectRatioMenuController,
                    builder: (_, __, ___) => Text(
                      aspectRatioTypeMap[defaultAspectRatioType] ?? '自动',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                    menuChildren: aspectRatioTypeMap.entries
                        .map((entry) => _dropdownItem(
                              label: entry.value,
                              selected: entry.key == defaultAspectRatioType,
                              onTap: () {
                                setting.put(SettingBoxKey.defaultAspectRatioType,
                                    entry.key);
                                setState(
                                    () => defaultAspectRatioType = entry.key);
                              },
                            ))
                        .toList(),
                  ),
                  onTap: () {
                    playerAspectRatioMenuController.isOpen
                        ? playerAspectRatioMenuController.close()
                        : playerAspectRatioMenuController.open();
                  },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDecoderTiles() {
    final tiles = <Widget>[
      SettingsSwitchTile(
        leading: const Icon(Icons.memory_rounded),
        title: '硬件解码',
        value: hAenable,
        onChanged: (v) async {
          hAenable = v;
          await setting.put(SettingBoxKey.hAenable, hAenable);
          setState(() {});
        },
      ),
      SettingsNavTile(
        leading: const Icon(Icons.developer_board_rounded),
        title: '硬件解码器',
        subtitle: '仅在硬件解码启用时生效',
        onTap: () => Modular.to.pushNamed('/settings/player/decoder'),
      ),
    ];

    if (Platform.isAndroid) {
      tiles.add(SettingsNavTile(
        leading: const Icon(Icons.videocam_rounded),
        title: '视频渲染器',
        subtitle: '选择视频输出方式',
        onTap: () => Modular.to.pushNamed('/settings/player/renderer'),
      ));
    }

    tiles.addAll([
      SettingsSwitchTile(
        leading: const Icon(Icons.memory_rounded),
        title: '低内存模式',
        subtitle: '禁用高级缓存以减少内存占用',
        value: lowMemoryMode,
        onChanged: (v) async {
          lowMemoryMode = v;
          await setting.put(SettingBoxKey.lowMemoryMode, lowMemoryMode);
          setState(() {});
        },
      ),
    ]);

    if (Platform.isAndroid) {
      tiles.add(SettingsSwitchTile(
        leading: const Icon(Icons.volume_up_rounded),
        title: '低延迟音频',
        subtitle: '启用OpenSLES音频输出以降低延时',
        value: androidEnableOpenSLES,
        onChanged: (v) async {
          androidEnableOpenSLES = v;
          await setting.put(
              SettingBoxKey.androidEnableOpenSLES, androidEnableOpenSLES);
          setState(() {});
        },
      ));
    }

    tiles.add(SettingsNavTile(
      leading: const Icon(Icons.hd_rounded),
      title: '超分辨率',
      onTap: () => Modular.to.pushNamed('/settings/player/super'),
      isLast: true,
    ));

    return tiles;
  }

  List<Widget> _buildBehaviorTiles() {
    return [
      SettingsSwitchTile(
        leading: const Icon(Icons.headphones_rounded),
        title: '后台播放',
        subtitle: '应用退到后台或熄屏时继续播放音频',
        value: backgroundPlayback,
        onChanged: (v) async {
          backgroundPlayback = v;
          await setting.put(SettingBoxKey.backgroundPlayback, backgroundPlayback);
          setState(() {});
        },
      ),
      SettingsSwitchTile(
        leading: const Icon(Icons.replay_rounded),
        title: '自动跳转',
        subtitle: '跳转到上次播放位置',
        value: playResume,
        onChanged: (v) async {
          playResume = v;
          await setting.put(SettingBoxKey.playResume, playResume);
          setState(() {});
        },
      ),
      SettingsSwitchTile(
        leading: const Icon(Icons.skip_next_rounded),
        title: '自动连播',
        subtitle: '当前视频播放完毕后自动播放下一集',
        value: autoPlayNext,
        onChanged: (v) async {
          autoPlayNext = v;
          await setting.put(SettingBoxKey.autoPlayNext, autoPlayNext);
          setState(() {});
        },
      ),
      if (Platform.isAndroid)
        SettingsSwitchTile(
          leading: const Icon(Icons.picture_in_picture_rounded),
          title: '自动进入画中画',
          subtitle: '切到后台时，自动进入画中画',
          value: androidAutoEnterPIP,
          onChanged: (v) async {
            androidAutoEnterPIP = v;
            await setting.put(
                SettingBoxKey.androidAutoEnterPIP, androidAutoEnterPIP);
            await PipUtils.setAndroidAutoEnterPIPEnabled(androidAutoEnterPIP);
            setState(() {});
          },
        ),
      SettingsSwitchTile(
        leading: const Icon(Icons.block_rounded),
        title: '广告过滤',
        subtitle: '强制启用HLS广告过滤，忽略规则设置',
        value: forceAdBlocker,
        onChanged: (v) async {
          forceAdBlocker = v;
          await setting.put(SettingBoxKey.forceAdBlocker, forceAdBlocker);
          setState(() {});
        },
      ),
      SettingsSwitchTile(
        leading: const Icon(Icons.animation_rounded),
        title: '禁用动画',
        subtitle: '禁用播放器内的过渡动画',
        value: playerDisableAnimations,
        onChanged: (v) async {
          playerDisableAnimations = v;
          await setting.put(
              SettingBoxKey.playerDisableAnimations, playerDisableAnimations);
          setState(() {});
        },
      ),
      if (!Utils.isDesktop())
        SettingsSwitchTile(
          leading: const Icon(Icons.swipe_rounded),
          title: '滑动手势',
          subtitle: '竖向滑动调节音量和亮度',
          value: brightnessVolumeGesture,
          onChanged: (v) async {
            brightnessVolumeGesture = v;
            await setting.put(
                SettingBoxKey.brightnessVolumeGesture, brightnessVolumeGesture);
            setState(() {});
          },
        ),
      SettingsSwitchTile(
        leading: const Icon(Icons.visibility_off_rounded),
        title: '隐身模式',
        subtitle: '不保留观看记录',
        value: privateMode,
        onChanged: (v) async {
          privateMode = v;
          await setting.put(SettingBoxKey.privateMode, privateMode);
          setState(() {});
        },
        isLast: true,
      ),
    ];
  }

  List<Widget> _buildDebugTiles() {
    return [
      SettingsSwitchTile(
        leading: const Icon(Icons.error_outline_rounded),
        title: '错误提示',
        subtitle: '显示播放器内部错误提示',
        value: showPlayerError,
        onChanged: (v) async {
          showPlayerError = v;
          await setting.put(SettingBoxKey.showPlayerError, showPlayerError);
          setState(() {});
        },
      ),
      SettingsSwitchTile(
        leading: const Icon(Icons.code_rounded),
        title: '调试模式',
        subtitle: '记录播放器内部日志',
        value: playerDebugMode,
        onChanged: (v) async {
          playerDebugMode = v;
          await setting.put(SettingBoxKey.playerDebugMode, playerDebugMode);
          setState(() {});
        },
      ),
      SettingsNavTile(
        leading: const Icon(Icons.list_alt_rounded),
        title: '日志等级',
        subtitle: playerLogLevelMap[playerLogLevel] ?? '???',
        trailing: MenuAnchor(
          consumeOutsideTap: true,
          controller: playerLogLevelMenuController,
          builder: (_, __, ___) => Text(
            playerLogLevelMap[playerLogLevel] ?? '???',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
          ),
          menuChildren: playerLogLevelMap.entries
              .map((e) => _dropdownItem(
                    label: e.value,
                    selected: e.key == playerLogLevel,
                    onTap: () {
                      setting.put(SettingBoxKey.playerLogLevel, e.key);
                      setState(() => playerLogLevel = e.key);
                    },
                  ))
              .toList(),
        ),
        onTap: () {
          playerLogLevelMenuController.isOpen
              ? playerLogLevelMenuController.close()
              : playerLogLevelMenuController.open();
        },
        isLast: true,
      ),
    ];
  }

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return SettingsNavTile(
      leading: Icon(icon),
      title: title,
      subtitle: label,
      trailing: SizedBox(
        width: 140,
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
      ),
      onTap: () {},
    );
  }

  Widget _dropdownItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return MenuItemButton(
      requestFocusOnHover: false,
      onPressed: onTap,
      child: SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.primary : scheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
