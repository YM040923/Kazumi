import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/palette_card.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_theme.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/theme_provider.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/settings/color_type.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  Box setting = GStorage.setting;
  late String defaultThemeMode;
  late String defaultThemeColor;
  late bool oledEnhance;
  late bool useDynamicColor;
  late bool showWindowButton;
  late bool useSystemFont;
  late final ThemeProvider themeProvider;
  final MenuController menuController = MenuController();

  @override
  void initState() {
    super.initState();
    defaultThemeMode =
        setting.get(SettingBoxKey.themeMode, defaultValue: 'system');
    defaultThemeColor =
        setting.get(SettingBoxKey.themeColor, defaultValue: 'default');
    oledEnhance = setting.get(SettingBoxKey.oledEnhance, defaultValue: false);
    useDynamicColor =
        setting.get(SettingBoxKey.useDynamicColor, defaultValue: false);
    showWindowButton =
        setting.get(SettingBoxKey.showWindowButton, defaultValue: false);
    useSystemFont =
        setting.get(SettingBoxKey.useSystemFont, defaultValue: false);
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
    }
  }

  void setTheme(Color? color) {
    final fontFamily = themeProvider.currentFontFamily;
    final defaultDarkTheme = KazumiTheme.buildTheme(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorSeed: color,
    );
    themeProvider.setTheme(
      KazumiTheme.buildTheme(
        brightness: Brightness.light,
        fontFamily: fontFamily,
        colorSeed: color,
      ),
      oledEnhance ? Utils.oledDarkTheme(defaultDarkTheme) : defaultDarkTheme,
    );
    defaultThemeColor = color?.value.toRadixString(16) ?? 'default';
    setting.put(SettingBoxKey.themeColor, defaultThemeColor);
  }

  void resetTheme() {
    final fontFamily = themeProvider.currentFontFamily;
    final defaultDarkTheme = KazumiTheme.buildTheme(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorSeed: Colors.green,
    );
    themeProvider.setTheme(
      KazumiTheme.buildTheme(
        brightness: Brightness.light,
        fontFamily: fontFamily,
        colorSeed: Colors.green,
      ),
      oledEnhance ? Utils.oledDarkTheme(defaultDarkTheme) : defaultDarkTheme,
    );
    defaultThemeColor = 'default';
    setting.put(SettingBoxKey.themeColor, 'default');
  }

  void updateTheme(String theme) async {
    switch (theme) {
      case 'dark':
        themeProvider.setThemeMode(ThemeMode.dark);
      case 'light':
        themeProvider.setThemeMode(ThemeMode.light);
      case 'system':
        themeProvider.setThemeMode(ThemeMode.system);
    }
    await setting.put(SettingBoxKey.themeMode, theme);
    setState(() => defaultThemeMode = theme);

    if (Platform.isWindows) {
      await windowManager.setBrightness(
        themeProvider.isEffectiveDark() ? Brightness.dark : Brightness.light,
      );
    }
  }

  void updateOledEnhance() {
    Color color;
    if (defaultThemeColor == 'default') {
      color = Colors.green;
    } else {
      color = Color(int.parse(defaultThemeColor, radix: 16));
    }
    setTheme(color);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) => onBackPressed(context),
      child: Scaffold(
        appBar: const SysAppBar(title: Text('外观设置')),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.md,
            vertical: KazumiSpacing.sm,
          ),
          children: [
            SettingsSectionCard(
              title: '外观',
              icon: Icons.palette_rounded,
              tiles: [
                SettingsNavTile(
                  leading: const Icon(Icons.brightness_6_rounded),
                  title: '深色模式',
                  subtitle: defaultThemeMode == 'light'
                      ? '浅色'
                      : (defaultThemeMode == 'dark' ? '深色' : '跟随系统'),
                  trailing: _themeModeSelector(),
                  onTap: () {
                    menuController.isOpen
                        ? menuController.close()
                        : menuController.open();
                  },
                ),
                SettingsNavTile(
                  leading: const Icon(Icons.color_lens_rounded),
                  title: '配色方案',
                  onTap: () => _showColorPicker(),
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: '动态配色',
                  subtitle: '仅支持安卓12及以上和桌面平台',
                  value: useDynamicColor,
                  onChanged: (value) async {
                    if (Platform.isIOS) return;
                    useDynamicColor = value;
                    await setting.put(
                        SettingBoxKey.useDynamicColor, useDynamicColor);
                    themeProvider.setDynamic(useDynamicColor);
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  leading: const Icon(Icons.font_download_rounded),
                  title: '使用系统字体',
                  subtitle: '关闭后使用 MI Sans 字体',
                  value: useSystemFont,
                  onChanged: (value) async {
                    useSystemFont = value;
                    await setting.put(
                        SettingBoxKey.useSystemFont, useSystemFont);
                    themeProvider.setFontFamily(useSystemFont);
                    setTheme(defaultThemeColor == 'default'
                        ? Colors.green
                        : Color(int.parse(defaultThemeColor, radix: 16)));
                    setState(() {});
                  },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.md),
            SettingsSectionCard(
              title: '深色模式增强',
              icon: Icons.dark_mode_rounded,
              tiles: [
                SettingsSwitchTile(
                  leading: const Icon(Icons.phone_android_rounded),
                  title: 'OLED优化',
                  subtitle: '深色模式下使用纯黑背景',
                  value: oledEnhance,
                  onChanged: (value) async {
                    oledEnhance = value;
                    await setting.put(SettingBoxKey.oledEnhance, oledEnhance);
                    updateOledEnhance();
                    setState(() {});
                  },
                  isLast: !Utils.isDesktop() && !Platform.isAndroid,
                ),
                if (Utils.isDesktop())
                  SettingsSwitchTile(
                    leading: const Icon(Icons.window_rounded),
                    title: '使用系统标题栏',
                    subtitle: '重启应用生效',
                    value: showWindowButton,
                    onChanged: (value) async {
                      showWindowButton = value;
                      await setting.put(
                          SettingBoxKey.showWindowButton, showWindowButton);
                      setState(() {});
                    },
                    isLast: !Platform.isAndroid,
                  ),
                if (Platform.isAndroid)
                  SettingsNavTile(
                    leading: const Icon(Icons.screenshot_monitor_rounded),
                    title: '屏幕帧率',
                    onTap: () =>
                        Modular.to.pushNamed('/settings/theme/display'),
                    isLast: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeModeSelector() {
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      consumeOutsideTap: true,
      controller: menuController,
      builder: (_, __, ___) => const SizedBox.shrink(),
      menuChildren: [
        _menuItem(
          icon: Icons.brightness_auto_rounded,
          label: '跟随系统',
          selected: defaultThemeMode == 'system',
          onTap: () => updateTheme('system'),
          scheme: scheme,
        ),
        _menuItem(
          icon: Icons.light_mode_rounded,
          label: '浅色',
          selected: defaultThemeMode == 'light',
          onTap: () => updateTheme('light'),
          scheme: scheme,
        ),
        _menuItem(
          icon: Icons.dark_mode_rounded,
          label: '深色',
          selected: defaultThemeMode == 'dark',
          onTap: () => updateTheme('dark'),
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return MenuItemButton(
      requestFocusOnHover: false,
      onPressed: onTap,
      child: SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.primary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker() async {
    KazumiDialog.show(
      builder: (context) {
        return AlertDialog(
          title: const Text('配色方案'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: Utils.isDesktop() ? 8 : 0,
                children: colorThemeTypes.map((e) {
                  final index = colorThemeTypes.indexOf(e);
                  return GestureDetector(
                    onTap: () {
                      index == 0 ? resetTheme() : setTheme(e['color']);
                      KazumiDialog.dismiss();
                    },
                    child: Column(
                      children: [
                        PaletteCard(
                          color: e['color'],
                          selected: (e['color']
                                      .value
                                      .toRadixString(16) ==
                                  defaultThemeColor ||
                              (defaultThemeColor == 'default' &&
                                  index == 0)),
                        ),
                        Text(e['label']),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}
