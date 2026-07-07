import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/utils/storage.dart';

class InterfaceSettingsPage extends StatefulWidget {
  const InterfaceSettingsPage({super.key});

  @override
  State<InterfaceSettingsPage> createState() => _InterfaceSettingsPageState();
}

class _InterfaceSettingsPageState extends State<InterfaceSettingsPage> {
  Box setting = GStorage.setting;
  late bool showRating;
  late String defaultPage;
  final MenuController defaultPageMenuController = MenuController();

  static const Map<String, String> defaultPageMap = {
    '/tab/popular/': '推荐',
    '/tab/timeline/': '时间表',
    '/tab/collect/': '追番',
    '/tab/my/': '我的',
  };

  @override
  void initState() {
    super.initState();
    showRating = setting.get(SettingBoxKey.showRating, defaultValue: true);
    defaultPage = setting.get(SettingBoxKey.defaultStartupPage,
        defaultValue: '/tab/popular/');
  }

  void updateDefaultPage(String page) {
    setting.put(SettingBoxKey.defaultStartupPage, page);
    setState(() => defaultPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                    const _InterfaceSettingsHeader(),
                    const SizedBox(height: KazumiSpacing.md),
                    SettingsSectionCard(
                      title: '启动',
                      icon: Icons.launch_rounded,
                      tiles: [
                        SettingsNavTile(
                          leading: const Icon(Icons.home_rounded),
                          title: '启动界面设置',
                          subtitle: '设置应用开启时的默认页面',
                          trailing: MenuAnchor(
                            consumeOutsideTap: true,
                            controller: defaultPageMenuController,
                            builder: (_, __, ___) {
                              return Text(
                                defaultPageMap[defaultPage] ?? '推荐',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              );
                            },
                            menuChildren: defaultPageMap.entries
                                .map(
                                  (entry) => MenuItemButton(
                                    requestFocusOnHover: false,
                                    onPressed: () =>
                                        updateDefaultPage(entry.key),
                                    child: SizedBox(
                                      height: 48,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            color: entry.key == defaultPage
                                                ? scheme.primary
                                                : scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          onTap: () {
                            defaultPageMenuController.isOpen
                                ? defaultPageMenuController.close()
                                : defaultPageMenuController.open();
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: KazumiSpacing.md),
                    SettingsSectionCard(
                      title: '显示',
                      icon: Icons.visibility_rounded,
                      tiles: [
                        SettingsSwitchTile(
                          leading: const Icon(Icons.star_outline_rounded),
                          title: '显示评分',
                          subtitle: '关闭后将在概览中隐藏评分信息',
                          value: showRating,
                          onChanged: (value) async {
                            showRating = value;
                            await setting.put(
                              SettingBoxKey.showRating,
                              showRating,
                            );
                            setState(() {});
                          },
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
    );
  }
}

class _InterfaceSettingsHeader extends StatelessWidget {
  const _InterfaceSettingsHeader();

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
                  Icons.dashboard_customize_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '界面设置',
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '管理启动页面、导航和内容显示偏好。',
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
