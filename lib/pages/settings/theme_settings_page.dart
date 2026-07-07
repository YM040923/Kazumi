import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/palette_card.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/appbar/desktop_window_controls.dart';
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/design/kazumi_theme.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/theme_provider.dart';
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

  void _applyThemeSelection(_ThemeSelection selection) {
    final fontFamily = themeProvider.currentFontFamily;
    final defaultDarkTheme = KazumiTheme.buildTheme(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorSeed: selection.colorSeed,
      preset: selection.preset,
    );
    themeProvider.setTheme(
      KazumiTheme.buildTheme(
        brightness: Brightness.light,
        fontFamily: fontFamily,
        colorSeed: selection.colorSeed,
        preset: selection.preset,
      ),
      oledEnhance ? Utils.oledDarkTheme(defaultDarkTheme) : defaultDarkTheme,
    );
  }

  _ThemeSelection _themeSelectionFromStorage(String value) {
    final preset = KazumiThemePreset.fromStorageValue(value);
    if (preset != null) {
      return _ThemeSelection(
        colorSeed: preset.isDefault ? preset.primary : null,
        preset: preset,
      );
    }

    try {
      return _ThemeSelection(
        colorSeed: Color(int.parse(value, radix: 16)),
      );
    } catch (_) {
      return const _ThemeSelection(
        colorSeed: Colors.green,
        preset: defaultThemePreset,
      );
    }
  }

  void _applyStoredTheme() {
    _applyThemeSelection(_themeSelectionFromStorage(defaultThemeColor));
  }

  void setThemePreset(KazumiThemePreset preset) {
    defaultThemeColor = preset.storageValue;
    _applyThemeSelection(
      _ThemeSelection(
        colorSeed: preset.isDefault ? preset.primary : null,
        preset: preset,
      ),
    );
    setting.put(SettingBoxKey.themeColor, defaultThemeColor);
  }

  void resetTheme() {
    setThemePreset(defaultThemePreset);
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
    _applyStoredTheme();
  }

  Future<void> _syncDesktopTitleBarStyle() async {
    if (!Utils.isDesktop()) return;
    DesktopWindowButtonMode.setShowNativeButtons(showWindowButton);
    await windowManager.setTitleBarStyle(
      (Platform.isMacOS || !showWindowButton)
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: showWindowButton,
    );
  }

  String _currentThemePresetLabel() {
    final preset = KazumiThemePreset.fromStorageValue(defaultThemeColor);
    if (preset != null) return preset.label;
    return '自定义颜色';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) => onBackPressed(context),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: WindowControlInset(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 18),
              children: [
                KazumiDesktopPageFrame(
                  maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _ThemeSettingsHeader(),
                      const SizedBox(height: KazumiSpacing.md),
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
                            subtitle: _currentThemePresetLabel(),
                            onTap: () => _showColorPicker(),
                          ),
                          SettingsSwitchTile(
                            leading: const Icon(Icons.auto_awesome_rounded),
                            title: '动态配色',
                            subtitle: '仅支持安卓 12 及以上和桌面平台',
                            value: useDynamicColor,
                            onChanged: (value) async {
                              if (Platform.isIOS) return;
                              useDynamicColor = value;
                              await setting.put(
                                SettingBoxKey.useDynamicColor,
                                useDynamicColor,
                              );
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
                                SettingBoxKey.useSystemFont,
                                useSystemFont,
                              );
                              themeProvider.setFontFamily(useSystemFont);
                              _applyStoredTheme();
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
                            title: 'OLED 优化',
                            subtitle: '深色模式下使用纯黑背景',
                            value: oledEnhance,
                            onChanged: (value) async {
                              oledEnhance = value;
                              await setting.put(
                                SettingBoxKey.oledEnhance,
                                oledEnhance,
                              );
                              updateOledEnhance();
                              setState(() {});
                            },
                            isLast: !Utils.isDesktop() && !Platform.isAndroid,
                          ),
                          if (Utils.isDesktop())
                            SettingsSwitchTile(
                              leading: const Icon(Icons.window_rounded),
                              title: '使用系统标题栏',
                              subtitle: '切换原生窗口栏和应用内窗口按钮',
                              value: showWindowButton,
                              onChanged: (value) async {
                                showWindowButton = value;
                                await setting.put(
                                  SettingBoxKey.showWindowButton,
                                  showWindowButton,
                                );
                                await _syncDesktopTitleBarStyle();
                                setState(() {});
                              },
                              isLast: !Platform.isAndroid,
                            ),
                          if (Platform.isAndroid)
                            SettingsNavTile(
                              leading: const Icon(
                                Icons.screenshot_monitor_rounded,
                              ),
                              title: '屏幕帧率',
                              onTap: () => Modular.to.pushNamed(
                                '/settings/theme/display',
                              ),
                              isLast: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                children: colorThemeTypes.map((theme) {
                  return GestureDetector(
                    onTap: () {
                      setThemePreset(theme);
                      KazumiDialog.dismiss();
                    },
                    child: Column(
                      children: [
                        PaletteCard(
                          preset: theme,
                          selected: defaultThemeColor == theme.storageValue ||
                              (defaultThemeColor == 'default' &&
                                  theme.isDefault),
                        ),
                        Text(theme.label),
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

class _ThemeSettingsHeader extends StatelessWidget {
  const _ThemeSettingsHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: dtb.DragToMoveArea(
        child: KazumiGlassSurface(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Modular.to.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: '返回',
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '外观设置',
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '切换主题、配色、字体和窗口外观。',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelection {
  const _ThemeSelection({
    this.colorSeed,
    this.preset,
  });

  final Color? colorSeed;
  final KazumiThemePreset? preset;
}
