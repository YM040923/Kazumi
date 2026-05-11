import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/utils/bangumi_sync_service.dart';
import 'package:kazumi/utils/logger.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/webdav.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';

class WebDavSettingsPage extends StatefulWidget {
  const WebDavSettingsPage({super.key});

  @override
  State<WebDavSettingsPage> createState() => _PlayerSettingsPageState();
}

class _PlayerSettingsPageState extends State<WebDavSettingsPage> {
  Box setting = GStorage.setting;
  late bool webDavEnable;
  late bool webDavEnableHistory;
  late bool webDavEnableCollect;
  late bool enableGitProxy;
  late bool bangumiSyncEnable;

  @override
  void initState() {
    super.initState();
    webDavEnable = setting.get(SettingBoxKey.webDavEnable, defaultValue: false);
    webDavEnableHistory =
        setting.get(SettingBoxKey.webDavEnableHistory, defaultValue: false);
    webDavEnableCollect =
        setting.get(SettingBoxKey.webDavEnableCollect, defaultValue: false);
    enableGitProxy =
        setting.get(SettingBoxKey.enableGitProxy, defaultValue: false);
    bangumiSyncEnable =
        setting.get(SettingBoxKey.bangumiSyncEnable, defaultValue: false);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  Future<void> syncHistoryWithWebDav() async {
    var webDavEnable =
        await setting.get(SettingBoxKey.webDavEnable, defaultValue: false);
    if (webDavEnable) {
      KazumiLogger().i('WebDav: manual history sync started');
      KazumiDialog.showToast(message: '正在同步观看记录');
      var webDav = WebDav();
      try {
        await webDav.ping();
        try {
          await webDav.syncHistory();
          KazumiLogger().i('WebDav: manual history sync completed');
          KazumiDialog.showToast(message: '观看记录同步完成');
        } catch (e) {
          KazumiLogger().w('WebDav: manual history sync failed', error: e);
          KazumiDialog.showToast(message: '观看记录同步失败 ${e.toString()}');
        }
      } catch (e) {
        KazumiLogger().w('WebDav: manual history sync ping failed', error: e);
        KazumiDialog.showToast(message: 'WebDav连接失败');
      }
    } else {
      KazumiDialog.showToast(message: '未开启WebDav同步或配置无效');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        onBackPressed(context);
      },
      child: Scaffold(
        appBar: const SysAppBar(title: Text('同步设置')),
        body: ListView(
          padding: const EdgeInsets.all(KazumiSpacing.lg),
          children: [
            Center(
              child: SizedBox(
                width: (MediaQuery.of(context).size.width > 1000) ? 1000 : null,
                child: Column(
                  children: [
                    SettingsSectionCard(
                      title: 'Github',
                      icon: Icons.code_rounded,
                      tiles: [
                        SettingsSwitchTile(
                          leading: const Icon(Icons.compare_arrows_rounded),
                          title: 'Github镜像',
                          subtitle: '使用镜像访问规则托管仓库',
                          value: enableGitProxy,
                          onChanged: (value) async {
                            enableGitProxy = value;
                            await setting.put(
                                SettingBoxKey.enableGitProxy, enableGitProxy);
                            setState(() {});
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: KazumiSpacing.sm),
                    SettingsSectionCard(
                      title: 'Bangumi',
                      icon: Icons.tv_rounded,
                      tiles: [
                        SettingsSwitchTile(
                          leading: const Icon(Icons.sync_rounded),
                          title: 'Bangumi 同步',
                          subtitle: '允许与Bangumi自动同步收藏/追番状态',
                          value: bangumiSyncEnable,
                          onChanged: (value) async {
                            final tBangumiEnableSync = value;
                            final bangumi = BangumiSyncService();
                            if (tBangumiEnableSync == true) {
                              final token = setting
                                  .get(SettingBoxKey.bangumiAccessToken,
                                      defaultValue: '')
                                  .toString()
                                  .trim();
                              if (token.isEmpty) {
                                KazumiDialog.showToast(
                                    message: '请先配置 Bangumi 的 Access Token');
                                return;
                              } else {
                                if (!bangumi.initialized) {
                                  try {
                                    await bangumi.init();
                                  } catch (e) {
                                    KazumiDialog.showToast(
                                        message: "Bangumi 初始化失败，请稍后再试");
                                    return;
                                  }
                                }
                              }
                            }
                            bangumiSyncEnable = tBangumiEnableSync;
                            await setting.put(
                                SettingBoxKey.bangumiSyncEnable, bangumiSyncEnable);
                            if (!mounted) {
                              return;
                            }
                            setState(() {});
                          },
                        ),
                        SettingsNavTile(
                          leading: const Icon(Icons.settings_rounded),
                          title: 'Bangumi 配置',
                          onTap: () async {
                            await Modular.to.pushNamed('/settings/bangumi/');
                            bangumiSyncEnable = setting.get(
                                SettingBoxKey.bangumiSyncEnable,
                                defaultValue: false);
                            setState(() {});
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: KazumiSpacing.sm),
                    SettingsSectionCard(
                      title: 'WEBDAV',
                      icon: Icons.cloud_rounded,
                      tiles: [
                        SettingsSwitchTile(
                          leading: const Icon(Icons.cloud_sync_rounded),
                          title: 'WEBDAV同步',
                          value: webDavEnable,
                          onChanged: (value) async {
                            webDavEnable = value;
                            if (!WebDav().initialized && webDavEnable) {
                              try {
                                await WebDav().init();
                              } catch (e) {
                                webDavEnable = false;
                                KazumiDialog.showToast(message: 'WEBDAV初始化失败 $e');
                              }
                            }
                            if (!webDavEnable) {
                              webDavEnableHistory = false;
                              webDavEnableCollect = false;
                              await setting.put(
                                  SettingBoxKey.webDavEnableHistory, false);
                              await setting.put(
                                  SettingBoxKey.webDavEnableCollect, false);
                            }
                            await setting.put(SettingBoxKey.webDavEnable, webDavEnable);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                        SettingsSwitchTile(
                          leading: const Icon(Icons.history_rounded),
                          title: '观看记录同步',
                          subtitle: '允许自动同步观看记录',
                          value: webDavEnableHistory,
                          onChanged: (value) async {
                            if (!webDavEnable) {
                              KazumiDialog.showToast(message: '请先开启WEBDAV同步');
                              return;
                            }
                            webDavEnableHistory = value;
                            await setting.put(
                                SettingBoxKey.webDavEnableHistory, webDavEnableHistory);
                            setState(() {});
                          },
                        ),
                        SettingsSwitchTile(
                          leading: const Icon(Icons.favorite_border_rounded),
                          title: '收藏同步',
                          subtitle: '允许 WebDAV 参与追番状态同步',
                          value: webDavEnableCollect,
                          onChanged: (value) async {
                            if (!webDavEnable) {
                              KazumiDialog.showToast(message: '请先开启WEBDAV同步');
                              return;
                            }
                            webDavEnableCollect = value;
                            await setting.put(
                                SettingBoxKey.webDavEnableCollect, webDavEnableCollect);
                            setState(() {});
                          },
                        ),
                        SettingsNavTile(
                          leading: const Icon(Icons.settings_rounded),
                          title: 'WEBDAV配置',
                          onTap: () async {
                            Modular.to.pushNamed('/settings/webdav/editor');
                          },
                        ),
                        SettingsNavTile(
                          leading: const Icon(Icons.sync_rounded),
                          title: '立即同步观看记录',
                          subtitle: '与WEBDAV双向合并观看记录',
                          trailing: IconButton(
                            icon: const Icon(Icons.sync_rounded),
                            onPressed: () {
                              syncHistoryWithWebDav();
                            },
                          ),
                          onTap: () {
                            syncHistoryWithWebDav();
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
