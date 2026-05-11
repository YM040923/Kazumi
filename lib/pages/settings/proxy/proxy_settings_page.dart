import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/proxy_manager.dart';

class ProxySettingsPage extends StatefulWidget {
  const ProxySettingsPage({super.key});

  @override
  State<ProxySettingsPage> createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends State<ProxySettingsPage> {
  Box setting = GStorage.setting;
  late bool proxyEnable;

  @override
  void initState() {
    super.initState();
    proxyEnable = setting.get(SettingBoxKey.proxyEnable, defaultValue: false);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
    }
  }

  Future<void> updateProxyEnable(bool value) async {
    if (value) {
      final proxyConfigured =
          setting.get(SettingBoxKey.proxyConfigured, defaultValue: false);
      if (!proxyConfigured) {
        KazumiDialog.showToast(message: '请先在代理配置中完成测试');
        return;
      }
      await setting.put(SettingBoxKey.proxyEnable, true);
      ProxyManager.applyProxy();
    } else {
      await setting.put(SettingBoxKey.proxyEnable, false);
      ProxyManager.clearProxy();
    }
    setState(() => proxyEnable = value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, _) => onBackPressed(context),
      child: Scaffold(
        appBar: const SysAppBar(title: Text('代理设置')),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.md,
            vertical: KazumiSpacing.sm,
          ),
          children: [
            SettingsSectionCard(
              title: '代理',
              icon: Icons.vpn_key_rounded,
              tiles: [
                SettingsSwitchTile(
                  leading: const Icon(Icons.power_settings_new_rounded),
                  title: '启用代理',
                  subtitle: '启用后网络请求将通过代理服务器',
                  value: proxyEnable,
                  onChanged: (v) => updateProxyEnable(v),
                ),
                SettingsNavTile(
                  leading: const Icon(Icons.settings_ethernet_rounded),
                  title: '代理配置',
                  subtitle: '配置代理服务器地址和认证信息',
                  onTap: () async {
                    await Modular.to.pushNamed('/settings/proxy/editor');
                    setState(() {
                      proxyEnable = setting.get(SettingBoxKey.proxyEnable,
                          defaultValue: false);
                    });
                  },
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
