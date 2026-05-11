import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/request/config/api_endpoints.dart';
import 'package:kazumi/utils/mortis.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final exitBehaviorTitles = <String>['退出 Kazumi', '最小化至托盘', '每次都询问'];
  late dynamic defaultDanmakuArea;
  late dynamic defaultThemeMode;
  late dynamic defaultThemeColor;
  Box setting = GStorage.setting;
  late int exitBehavior =
      setting.get(SettingBoxKey.exitBehavior, defaultValue: 2);
  late bool autoUpdate;
  double _cacheSizeMB = -1;
  final MyController myController = Modular.get<MyController>();
  final MenuController menuController = MenuController();

  @override
  void initState() {
    super.initState();
    autoUpdate = setting.get(SettingBoxKey.autoUpdate, defaultValue: true);
    _getCacheSize();
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  Future<Directory> _getCacheDir() async {
    Directory tempDir = await getTemporaryDirectory();
    return Directory('${tempDir.path}/libCachedImageData');
  }

  Future<void> _getCacheSize() async {
    Directory cacheDir = await _getCacheDir();

    if (await cacheDir.exists()) {
      int totalSizeBytes = await _getTotalSizeOfFilesInDir(cacheDir);
      double totalSizeMB = (totalSizeBytes / (1024 * 1024));

      if (mounted) {
        setState(() {
          _cacheSizeMB = totalSizeMB;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _cacheSizeMB = 0.0;
        });
      }
    }
  }

  Future<int> _getTotalSizeOfFilesInDir(final Directory directory) async {
    final List<FileSystemEntity> children = directory.listSync();
    int total = 0;

    try {
      for (final FileSystemEntity child in children) {
        if (child is File) {
          final int length = await child.length();
          total += length;
        } else if (child is Directory) {
          total += await _getTotalSizeOfFilesInDir(child);
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> _clearCache() async {
    final Directory libCacheDir = await _getCacheDir();
    await libCacheDir.delete(recursive: true);
    _getCacheSize();
  }

  void _showCacheDialog() {
    KazumiDialog.show(
      builder: (context) {
        return AlertDialog(
          title: const Text('缓存管理'),
          content: const Text('缓存为番剧封面, 清除后加载时需要重新下载,确认要清除缓存吗?'),
          actions: [
            TextButton(
              onPressed: () {
                KazumiDialog.dismiss();
              },
              child: Text(
                '取消',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  _clearCache();
                } catch (_) {}
                KazumiDialog.dismiss();
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        onBackPressed(context);
      },
      child: Scaffold(
        appBar: const SysAppBar(title: Text('关于')),
        // backgroundColor: Colors.transparent,
        body: ListView(
          padding: const EdgeInsets.all(KazumiSpacing.lg),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  SettingsSectionCard(
                    title: '开源信息',
                    icon: Icons.article_outlined,
                    tiles: [
                      SettingsNavTile(
                        leading: const Icon(Icons.description_outlined),
                        title: '开源许可证',
                        subtitle: '查看所有开源许可证',
                        isLast: true,
                        onTap: () {
                          Modular.to.pushNamed('/settings/about/license');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: KazumiSpacing.md),
                  SettingsSectionCard(
                    title: '外部链接',
                    icon: Icons.link,
                    tiles: [
                      SettingsNavTile(
                        leading: const Icon(Icons.home_outlined),
                        title: '项目主页',
                        onTap: () {
                          launchUrl(Uri.parse(ApiEndpoints.projectUrl),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                      SettingsNavTile(
                        leading: const Icon(Icons.code),
                        title: '代码仓库',
                        trailing: const Text('Github'),
                        onTap: () {
                          launchUrl(Uri.parse(ApiEndpoints.sourceUrl),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                      SettingsNavTile(
                        leading: const Icon(Icons.brush_outlined),
                        title: '图标创作',
                        trailing: const Text('Pixiv'),
                        onTap: () {
                          launchUrl(Uri.parse(ApiEndpoints.iconUrl),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                      SettingsNavTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: '番剧索引',
                        trailing: const Text('Bangumi'),
                        onTap: () {
                          launchUrl(Uri.parse(ApiEndpoints.bangumiIndex),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                      SettingsNavTile(
                        leading: const Icon(Icons.image_search),
                        title: '以图搜番',
                        trailing: const Text('trace.moe'),
                        onTap: () {
                          launchUrl(Uri.parse('https://trace.moe'),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                      SettingsNavTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: '弹幕来源',
                        subtitle: 'ID: ${mortis['id']}',
                        trailing: const Text('DanDanPlay'),
                        isLast: true,
                        onTap: () {
                          launchUrl(Uri.parse(ApiEndpoints.dandanIndex),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                    ],
                  ),
                  if (Utils.isDesktop()) ...[
                    const SizedBox(height: KazumiSpacing.md),
                    SettingsSectionCard(
                      title: '默认行为',
                      icon: Icons.touch_app_outlined,
                      tiles: [
                        SettingsNavTile(
                          leading: const Icon(Icons.exit_to_app),
                          title: '关闭时',
                          trailing: MenuAnchor(
                            consumeOutsideTap: true,
                            controller: menuController,
                            builder: (_, __, ___) {
                              return Text(exitBehaviorTitles[exitBehavior]);
                            },
                            menuChildren: [
                              for (int i = 0; i < 3; i++)
                                MenuItemButton(
                                  requestFocusOnHover: false,
                                  onPressed: () {
                                    exitBehavior = i;
                                    setting.put(SettingBoxKey.exitBehavior, i);
                                    setState(() {});
                                  },
                                  child: Container(
                                    height: 48,
                                    constraints: BoxConstraints(minWidth: 112),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        exitBehaviorTitles[i],
                                        style: TextStyle(
                                          color: i == exitBehavior
                                              ? Theme.of(context).colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          isLast: true,
                          onTap: () {
                            if (menuController.isOpen) {
                              menuController.close();
                            } else {
                              menuController.open();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: KazumiSpacing.md),
                  SettingsSectionCard(
                    title: '支持',
                    icon: Icons.support_outlined,
                    tiles: [
                      SettingsNavTile(
                        leading: const Icon(Icons.bug_report_outlined),
                        title: '错误日志',
                        isLast: true,
                        onTap: () {
                          Modular.to.pushNamed('/settings/about/logs');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: KazumiSpacing.md),
                  SettingsSectionCard(
                    title: '存储',
                    icon: Icons.sd_storage_outlined,
                    tiles: [
                      SettingsNavTile(
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: '清除缓存',
                        trailing: _cacheSizeMB == -1
                            ? const Text('统计中...')
                            : Text('${_cacheSizeMB.toStringAsFixed(2)}MB'),
                        isLast: true,
                        onTap: () {
                          _showCacheDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: KazumiSpacing.md),
                  SettingsSectionCard(
                    title: '应用更新',
                    icon: Icons.system_update_outlined,
                    tiles: [
                      SettingsSwitchTile(
                        leading: const Icon(Icons.system_update),
                        title: '自动更新',
                        value: autoUpdate,
                        onChanged: (value) async {
                          autoUpdate = value;
                          await setting.put(SettingBoxKey.autoUpdate, autoUpdate);
                          setState(() {});
                        },
                      ),
                      SettingsNavTile(
                        leading: const Icon(Icons.update),
                        title: '检查更新',
                        trailing: Text('当前版本 ${ApiEndpoints.version}'),
                        isLast: true,
                        onTap: () {
                          myController.checkUpdate();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
