import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/anti_crawler_config.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/widget/settings_components.dart';
import 'package:kazumi/design/design_tokens.dart';

class PluginEditorPage extends StatefulWidget {
  const PluginEditorPage({
    super.key,
  });

  @override
  State<PluginEditorPage> createState() => _PluginEditorPageState();
}

class _PluginEditorPageState extends State<PluginEditorPage> {
  final PluginsController pluginsController = Modular.get<PluginsController>();
  final TextEditingController apiController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController versionController = TextEditingController();
  final TextEditingController userAgentController = TextEditingController();
  final TextEditingController baseURLController = TextEditingController();
  final TextEditingController searchURLController = TextEditingController();
  final TextEditingController searchListController = TextEditingController();
  final TextEditingController searchNameController = TextEditingController();
  final TextEditingController searchResultController = TextEditingController();
  final TextEditingController chapterRoadsController = TextEditingController();
  final TextEditingController chapterResultController = TextEditingController();
  final TextEditingController refererController = TextEditingController();
  bool muliSources = true;
  bool useWebview = true;
  bool useNativePlayer = true;
  bool usePost = false;
  bool useLegacyParser = false;
  bool adBlocker = false;

  // AntiCrawler fields
  final TextEditingController captchaImageController = TextEditingController();
  final TextEditingController captchaInputController = TextEditingController();
  final TextEditingController captchaButtonController = TextEditingController();
  bool antiCrawlerEnabled = false;
  int captchaType = CaptchaType.imageCaptcha;
  final MenuController captchaTypeMenuController = MenuController();

  static const Map<int, String> _captchaTypeMap = {
    CaptchaType.imageCaptcha: '图片验证码',
    CaptchaType.autoClickButton: '自动点击按钮',
  };

  late final Plugin plugin;

  @override
  void initState() {
    super.initState();
    plugin = Modular.args.data as Plugin;
    apiController.text = plugin.api;
    typeController.text = plugin.type;
    nameController.text = plugin.name;
    versionController.text = plugin.version;
    userAgentController.text = plugin.userAgent;
    baseURLController.text = plugin.baseUrl;
    searchURLController.text = plugin.searchURL;
    searchListController.text = plugin.searchList;
    searchNameController.text = plugin.searchName;
    searchResultController.text = plugin.searchResult;
    chapterRoadsController.text = plugin.chapterRoads;
    chapterResultController.text = plugin.chapterResult;
    refererController.text = plugin.referer;
    muliSources = plugin.muliSources;
    useWebview = plugin.useWebview;
    useNativePlayer = plugin.useNativePlayer;
    usePost = plugin.usePost;
    useLegacyParser = plugin.useLegacyParser;
    adBlocker = plugin.adBlocker;
    antiCrawlerEnabled = plugin.antiCrawlerConfig.enabled;
    captchaType = plugin.antiCrawlerConfig.captchaType;
    captchaImageController.text = plugin.antiCrawlerConfig.captchaImage;
    captchaInputController.text = plugin.antiCrawlerConfig.captchaInput;
    captchaButtonController.text = plugin.antiCrawlerConfig.captchaButton;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SysAppBar(
        title: Text('规则编辑器'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KazumiSpacing.lg),
        child: Center(
          child: SizedBox(
            width: (MediaQuery.of(context).size.width > 1000) ? 1000 : null,
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: versionController,
                  decoration: const InputDecoration(
                      labelText: 'Version', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: baseURLController,
                  decoration: const InputDecoration(
                      labelText: 'BaseURL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: searchURLController,
                  decoration: const InputDecoration(
                      labelText: 'SearchURL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: searchListController,
                  decoration: const InputDecoration(
                      labelText: 'SearchList', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: searchNameController,
                  decoration: const InputDecoration(
                      labelText: 'SearchName', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: searchResultController,
                  decoration: const InputDecoration(
                      labelText: 'SearchResult', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: chapterRoadsController,
                  decoration: const InputDecoration(
                      labelText: 'ChapterRoads', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: chapterResultController,
                  decoration: const InputDecoration(
                      labelText: 'ChapterResult', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ExpansionTile(
                  title: const Text('高级选项'),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  children: [
                    SettingsSectionCard(
                      title: '行为设置',
                      icon: Icons.tune_rounded,
                      tiles: [
                        SettingsSwitchTile(
                          leading: const Icon(Icons.code_rounded),
                          title: '简易解析',
                          subtitle: '使用简易解析器而不是现代解析器',
                          value: useLegacyParser,
                          onChanged: (v) => setState(() => useLegacyParser = v),
                        ),
                        SettingsSwitchTile(
                          leading: const Icon(Icons.http_rounded),
                          title: 'POST',
                          subtitle: '使用 POST 而不是 GET 进行检索',
                          value: usePost,
                          onChanged: (v) => setState(() => usePost = v),
                        ),
                        SettingsSwitchTile(
                          leading: const Icon(Icons.play_circle_outline_rounded),
                          title: '内置播放器',
                          subtitle: '使用内置播放器播放视频',
                          value: useNativePlayer,
                          onChanged: (v) => setState(() => useNativePlayer = v),
                        ),
                        SettingsSwitchTile(
                          leading: const Icon(Icons.block_rounded),
                          title: '广告过滤',
                          subtitle: '启用 HLS 广告过滤',
                          value: adBlocker,
                          onChanged: (v) => setState(() => adBlocker = v),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: KazumiSpacing.sm),
                    SettingsSectionCard(
                      title: '网络设置',
                      icon: Icons.wifi_rounded,
                      tiles: [
                        _buildTextFieldTile(
                          controller: userAgentController,
                          label: 'UserAgent',
                        ),
                        _buildTextFieldTile(
                          controller: refererController,
                          label: 'Referer',
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: KazumiSpacing.sm),
                    SettingsSectionCard(
                      title: '反反爬虫配置',
                      icon: Icons.shield_rounded,
                      tiles: [
                        SettingsSwitchTile(
                          leading: const Icon(Icons.enhanced_encryption_rounded),
                          title: '启用反反爬虫',
                          subtitle: '检索失败时显示验证码验证按钮而非重试',
                          value: antiCrawlerEnabled,
                          onChanged: (v) => setState(() => antiCrawlerEnabled = v),
                        ),
                        if (antiCrawlerEnabled) ...[
                          _buildCaptchaTypeTile(),
                          if (captchaType == CaptchaType.imageCaptcha) ...[
                            _buildTextFieldTile(
                              controller: captchaImageController,
                              label: 'CaptchaImage (XPath)',
                              hint: '//img[@class="captcha"]',
                              helper: '验证码图片元素的 XPath',
                            ),
                            _buildTextFieldTile(
                              controller: captchaInputController,
                              label: 'CaptchaInput (XPath)',
                              hint: '//input[@name="captcha"]',
                              helper: '验证码输入框元素的 XPath',
                            ),
                          ],
                          _buildTextFieldTile(
                            controller: captchaButtonController,
                            label: captchaType == CaptchaType.imageCaptcha
                                ? 'CaptchaButton (XPath)'
                                : 'VerifyButton (XPath)',
                            hint: '//button[@type="submit"]',
                            helper: captchaType == CaptchaType.imageCaptcha
                                ? '验证提交按钮元素的 XPath'
                                : '验证按钮元素的 XPath，检测到后自动点击',
                            isLast: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: null,
            child: const Icon(Icons.bug_report),
            onPressed: () async {
              Plugin pluginText = Plugin(
                  api: apiController.text,
                  type: typeController.text,
                  name: nameController.text,
                  version: versionController.text,
                  muliSources: muliSources,
                  useWebview: useWebview,
                  useNativePlayer: useNativePlayer,
                  usePost: usePost,
                  useLegacyParser: useLegacyParser,
                  adBlocker: adBlocker,
                  userAgent: userAgentController.text,
                  baseUrl: baseURLController.text,
                  searchURL: searchURLController.text,
                  searchList: searchListController.text,
                  searchName: searchNameController.text,
                  searchResult: searchResultController.text,
                  chapterRoads: chapterRoadsController.text,
                  chapterResult: chapterResultController.text,
                  referer: refererController.text,
                  antiCrawlerConfig: AntiCrawlerConfig(
                    enabled: antiCrawlerEnabled,
                    captchaType: captchaType,
                    captchaImage: captchaImageController.text,
                    captchaInput: captchaInputController.text,
                    captchaButton: captchaButtonController.text,
                  ));
              Modular.to.pushNamed('/settings/plugin/test', arguments: pluginText);
            },
          ),
          SizedBox(width: 15),
          FloatingActionButton(
            heroTag: null,
            child: const Icon(Icons.save),
            onPressed: () async {
              plugin.api = apiController.text;
              plugin.type = typeController.text;
              plugin.name = nameController.text;
              plugin.version = versionController.text;
              plugin.userAgent = userAgentController.text;
              plugin.baseUrl = baseURLController.text;
              plugin.searchURL = searchURLController.text;
              plugin.searchList = searchListController.text;
              plugin.searchName = searchNameController.text;
              plugin.searchResult = searchResultController.text;
              plugin.chapterRoads = chapterRoadsController.text;
              plugin.chapterResult = chapterResultController.text;
              plugin.muliSources = muliSources;
              plugin.useWebview = useWebview;
              plugin.useNativePlayer = useNativePlayer;
              plugin.usePost = usePost;
              plugin.useLegacyParser = useLegacyParser;
              plugin.adBlocker = adBlocker;
              plugin.referer = refererController.text;
              plugin.antiCrawlerConfig = AntiCrawlerConfig(
                enabled: antiCrawlerEnabled,
                captchaType: captchaType,
                captchaImage: captchaImageController.text,
                captchaInput: captchaInputController.text,
                captchaButton: captchaButtonController.text,
              );
              pluginsController.updatePlugin(plugin);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldTile({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helper,
    bool isLast = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.lg,
            vertical: KazumiSpacing.sm,
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              helperText: helper,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: KazumiSpacing.lg + 22 + KazumiSpacing.md,
            endIndent: KazumiSpacing.lg,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
      ],
    );
  }

  Widget _buildCaptchaTypeTile() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: KazumiSpacing.lg,
            vertical: 0,
          ),
          minVerticalPadding: 0,
          leading: IconTheme(
            data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
            child: const Icon(Icons.category_rounded),
          ),
          title: Text(
            '验证类型',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
          subtitle: Text(
            captchaType == CaptchaType.imageCaptcha
                ? '图片验证码（展示验证码图片，用户手动输入）'
                : '自动点击验证按钮（检测到按钮后自动模拟点击）',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          trailing: MenuAnchor(
            consumeOutsideTap: true,
            controller: captchaTypeMenuController,
            builder: (_, __, ___) => Text(
              _captchaTypeMap[captchaType] ?? '未知',
            ),
            menuChildren: [
              for (final entry in _captchaTypeMap.entries)
                MenuItemButton(
                  requestFocusOnHover: false,
                  onPressed: () => setState(() => captchaType = entry.key),
                  child: Container(
                    height: 48,
                    constraints: const BoxConstraints(minWidth: 160),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: entry.key == captchaType
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            if (captchaTypeMenuController.isOpen) {
              captchaTypeMenuController.close();
            } else {
              captchaTypeMenuController.open();
            }
          },
        ),
        Divider(
          height: 1,
          indent: KazumiSpacing.lg + 22 + KazumiSpacing.md,
          endIndent: KazumiSpacing.lg,
          color: scheme.outlineVariant,
        ),
      ],
    );
  }
}
