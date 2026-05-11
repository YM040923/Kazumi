import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:provider/provider.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late NavigationBarState navigationBarState;

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
    navigationBarState.updateSelectedIndex(0);
    Modular.to.navigate('/tab/popular/');
  }

  @override
  void initState() {
    super.initState();
    navigationBarState =
        Provider.of<NavigationBarState>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        onBackPressed(context);
      },
      child: Scaffold(
        appBar: const SysAppBar(title: Text('我的'), needTopOffset: false),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.md,
            vertical: KazumiSpacing.sm,
          ),
          children: [
            const SettingsSectionCard(
              title: '播放历史与视频源',
              icon: Icons.play_circle_outline_rounded,
              tiles: [
                SettingsNavTile(
                  leading: Icon(Icons.history_rounded),
                  title: '历史记录',
                  subtitle: '查看播放历史记录',
                  onTap: _navToHistory,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.download_rounded),
                  title: '下载管理',
                  subtitle: '查看和管理离线下载',
                  onTap: _navToDownload,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.settings_rounded),
                  title: '下载设置',
                  subtitle: '配置下载并发数等参数',
                  onTap: _navToDownloadSettings,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.extension_rounded),
                  title: '规则管理',
                  subtitle: '管理番剧资源规则',
                  onTap: _navToPlugin,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.md),
            const SettingsSectionCard(
              title: '播放器设置',
              icon: Icons.play_circle_filled_rounded,
              tiles: [
                SettingsNavTile(
                  leading: Icon(Icons.display_settings_rounded),
                  title: '播放设置',
                  subtitle: '设置播放器相关参数',
                  onTap: _navToPlayer,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.subtitles_rounded),
                  title: '弹幕设置',
                  subtitle: '设置弹幕相关参数',
                  onTap: _navToDanmaku,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.keyboard_rounded),
                  title: '操作设置',
                  subtitle: '设置播放器按键映射',
                  onTap: _navToKeyboard,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.vpn_key_rounded),
                  title: '代理设置',
                  subtitle: '配置HTTP代理',
                  onTap: _navToProxy,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.md),
            const SettingsSectionCard(
              title: '应用与外观',
              icon: Icons.palette_outlined,
              tiles: [
                SettingsNavTile(
                  leading: Icon(Icons.palette_rounded),
                  title: '外观设置',
                  subtitle: '设置应用主题和刷新率',
                  onTap: _navToTheme,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.pages_rounded),
                  title: '界面设置',
                  subtitle: '设置应用界面样式',
                  onTap: _navToInterface,
                ),
                SettingsNavTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: '同步设置',
                  subtitle: '设置同步参数',
                  onTap: _navToWebdav,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: KazumiSpacing.md),
            const SettingsSectionCard(
              title: '其他',
              icon: Icons.more_horiz_rounded,
              tiles: [
                SettingsNavTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: '关于',
                  subtitle: '版本信息与致谢',
                  onTap: _navToAbout,
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

  // Navigation callbacks (static tear-offs for const constructors)
  static void _navToHistory() => Modular.to.pushNamed('/settings/history/');
  static void _navToDownload() => Modular.to.pushNamed('/settings/download/');
  static void _navToDownloadSettings() =>
      Modular.to.pushNamed('/settings/download-settings');
  static void _navToPlugin() => Modular.to.pushNamed('/settings/plugin/');
  static void _navToPlayer() => Modular.to.pushNamed('/settings/player');
  static void _navToDanmaku() => Modular.to.pushNamed('/settings/danmaku/');
  static void _navToKeyboard() => Modular.to.pushNamed('/settings/keyboard');
  static void _navToProxy() => Modular.to.pushNamed('/settings/proxy');
  static void _navToTheme() => Modular.to.pushNamed('/settings/theme');
  static void _navToInterface() =>
      Modular.to.pushNamed('/settings/interface');
  static void _navToWebdav() => Modular.to.pushNamed('/settings/webdav/');
  static void _navToAbout() => Modular.to.pushNamed('/settings/about/');
}
