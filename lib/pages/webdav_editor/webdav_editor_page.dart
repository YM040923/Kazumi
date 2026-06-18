import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/settings_page_shell.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/webdav.dart';

class WebDavEditorPage extends StatefulWidget {
  const WebDavEditorPage({
    super.key,
  });

  @override
  State<WebDavEditorPage> createState() => _WebDavEditorPageState();
}

class _WebDavEditorPageState extends State<WebDavEditorPage> {
  final TextEditingController webDavURLController = TextEditingController();
  final TextEditingController webDavUsernameController =
      TextEditingController();
  final TextEditingController webDavPasswordController =
      TextEditingController();
  Box setting = GStorage.setting;
  bool passwordVisible = false;

  @override
  void initState() {
    super.initState();
    webDavURLController.text =
        setting.get(SettingBoxKey.webDavURL, defaultValue: '');
    webDavUsernameController.text =
        setting.get(SettingBoxKey.webDavUsername, defaultValue: '');
    webDavPasswordController.text =
        setting.get(SettingBoxKey.webDavPassword, defaultValue: '');
  }

  @override
  void dispose() {
    webDavURLController.dispose();
    webDavUsernameController.dispose();
    webDavPasswordController.dispose();
    super.dispose();
  }

  Future<void> saveAndTest() async {
    setting.put(SettingBoxKey.webDavURL, webDavURLController.text);
    setting.put(SettingBoxKey.webDavUsername, webDavUsernameController.text);
    setting.put(SettingBoxKey.webDavPassword, webDavPasswordController.text);
    final webDav = WebDav();
    try {
      await webDav.init();
    } catch (e) {
      KazumiDialog.showToast(message: '配置失败 ${e.toString()}');
      await setting.put(SettingBoxKey.webDavEnable, false);
      return;
    }
    KazumiDialog.showToast(message: '配置成功, 开始测试');
    try {
      await webDav.ping();
      KazumiDialog.showToast(message: '测试成功');
    } catch (e) {
      KazumiDialog.showToast(message: '测试失败 ${e.toString()}');
      await setting.put(SettingBoxKey.webDavEnable, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KazumiSettingsPageShell(
        title: 'WebDAV 配置',
        subtitle: '填写云端同步地址和账号信息，保存后会立即进行连接测试。',
        icon: Icons.cloud_queue_rounded,
        actions: FilledButton.icon(
          onPressed: saveAndTest,
          icon: const Icon(Icons.save_rounded),
          label: const Text('保存并测试'),
        ),
        children: [
          TextField(
            controller: webDavURLController,
            decoration: const InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: KazumiSpacing.md),
          TextField(
            controller: webDavUsernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: KazumiSpacing.md),
          TextField(
            controller: webDavPasswordController,
            obscureText: !passwordVisible,
            decoration: InputDecoration(
              labelText: '密码',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    passwordVisible = !passwordVisible;
                  });
                },
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
