import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop shell and verification window stay resize-safe', () {
    final menuSource = File('lib/pages/menu/menu.dart').readAsStringSync();
    final desktopLayoutSource =
        File('lib/design/desktop_layout.dart').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final windowsRunnerSource =
        File('windows/runner/main.cpp').readAsStringSync();

    for (final marker in [
      '_MediaSideBar',
      '_SidebarBrand',
      '_MediaNavCluster',
      '_MediaNavButton',
      'KazumiDesktopShell.sidebarWidth',
      '_ConstrainedRouterOutlet',
      'size: Size(constraints.maxWidth, constraints.maxHeight)',
      'UiVerification.route',
    ]) {
      expect(menuSource, contains(marker));
    }

    expect(menuSource, isNot(contains('NavigationRail(')));
    expect(menuSource, isNot(contains('NavigationRailDestination')));
    expect(menuSource, isNot(contains('PageView.builder')));

    expect(desktopLayoutSource, contains('sidebarWidth = 86'));
    expect(desktopLayoutSource, contains('pageMaxWidth = 920'));
    expect(desktopLayoutSource, contains('mediaPageMaxWidth = 1560'));
    expect(desktopLayoutSource, contains('final frameWidth'));
    expect(desktopLayoutSource, contains('width: frameWidth'));

    expect(mainSource, contains('_desktopMinimumWindowSize = Size(960, 640)'));
    expect(mainSource, contains('const Size(1360, 860)'));
    expect(
        mainSource, contains('_initialDesktopWindowSize(initialWindowSize)'));
    expect(mainSource, contains('_initialDesktopWindowPosition()'));
    expect(mainSource, contains('SettingBoxKey.desktopWindowWidth'));
    expect(mainSource, contains('SettingBoxKey.desktopWindowHeight'));
    expect(mainSource,
        isNot(contains('await windowManager.setSize(desktopWindowSize)')));
    expect(windowsRunnerSource, contains('kDefaultWindowWidth = 1280'));
    expect(windowsRunnerSource, contains('kDefaultWindowHeight = 860'));
    expect(windowsRunnerSource, contains('kMinimumWindowWidth = 960'));
    expect(windowsRunnerSource, contains('EnsureUsableWindowSize(hwnd)'));
    expect(windowsRunnerSource,
        isNot(contains('Win32Window::Size size(1280, 720)')));
  });

  test('discover page keeps the approved media-forward structure', () {
    final source =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();

    for (final marker in [
      '_buildSpotlightBoard',
      '_SpotlightCopy',
      '_SpotlightThumbnailRail',
      '_SpotlightThumbnailButton',
      '_FeaturedPoster',
      '_TrendCategoryBar',
      '_MediaFilterHeader',
      '_DesktopContentFrame',
      '_ContentWidthMetrics',
      '_spotlightAutoPlayTimer',
      'Timer.periodic',
      'popularPosterGridColumnCount',
      'popularPosterGridGap',
      'popularPosterGridTextHeight',
      'bestBangumiPosterImage',
    ]) {
      expect(source, contains(marker));
    }

    expect(source, isNot(contains('CustomDropdownMenu')));
    expect(source, isNot(contains('Navigator.push<String>')));
    expect(source, isNot(contains('showTagMenu')));
    expect(source, isNot(contains('CinematicBangumiHero')));
  });

  test('desktop window controls and discover shortcuts avoid duplicates', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final appWidgetSource = File('lib/app_widget.dart').readAsStringSync();
    final storageSource = File('lib/utils/storage.dart').readAsStringSync();
    final menuSource = File('lib/pages/menu/menu.dart').readAsStringSync();
    final windowControlsSource =
        File('lib/bean/appbar/desktop_window_controls.dart').readAsStringSync();
    final windowControlsHostSource =
        File('lib/bean/appbar/window_control_inset.dart').readAsStringSync();
    final sysAppBarSource =
        File('lib/bean/appbar/sys_app_bar.dart').readAsStringSync();
    final popularSource =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();
    final timelineSource =
        File('lib/pages/timeline/timeline_page.dart').readAsStringSync();
    final infoSource = File('lib/pages/info/info_page.dart').readAsStringSync();
    final searchSource =
        File('lib/pages/search/search_page.dart').readAsStringSync();
    final settingsSource = File('lib/pages/my/my_page.dart').readAsStringSync();
    final displayModeSource =
        File('lib/pages/settings/displaymode_settings.dart').readAsStringSync();
    final storageErrorSource =
        File('lib/pages/error/storage_error_page.dart').readAsStringSync();
    final danmakuShieldSheetSource =
        File('lib/pages/settings/danmaku/danmaku_shield_settings_sheet.dart')
            .readAsStringSync();
    final indexModuleSource =
        File('lib/pages/index_module.dart').readAsStringSync();

    for (final marker in [
      'desktopWindowWidth',
      'desktopWindowHeight',
    ]) {
      expect(storageSource, contains(marker));
    }
    expect(
        mainSource, contains('_initialDesktopWindowSize(initialWindowSize)'));
    expect(mainSource,
        contains('GStorage.setting.get(SettingBoxKey.desktopWindowWidth'));
    expect(appWidgetSource, contains('_persistDesktopWindowPlacement'));
    expect(appWidgetSource, contains('onWindowResize'));
    expect(appWidgetSource, contains('windowManager.getSize()'));

    expect(menuSource, isNot(contains('_SearchDockButton')));
    expect(menuSource, isNot(contains('onSearch')));

    for (final marker in [
      'class DesktopWindowControls',
      'class DesktopWindowControlsOverlay',
      'WindowControlMetrics.controlWidth',
      'WindowControlMetrics.controlHeight',
      'width: WindowControlMetrics.buttonWidth',
      'height: WindowControlMetrics.controlHeight',
      'class _OverlayWindowControls',
      '_windowButton(',
      'class _CenteredMinimizeIcon',
      'windowManager.minimize()',
      'windowManager.isMaximized()',
      'windowManager.unmaximize()',
      'windowManager.maximize()',
      'windowManager.close()',
      'showWindowButton',
    ]) {
      expect(windowControlsSource, contains(marker));
    }
    expect(appWidgetSource, contains('DesktopWindowControlsOverlay'));
    expect(appWidgetSource, contains('builder: (context, child)'));
    expect(
        appWidgetSource, contains('child: child ?? const SizedBox.shrink()'));

    expect(sysAppBarSource, contains('DesktopWindowActionRail'));
    expect(windowControlsHostSource, contains('class WindowControlInset'));
    expect(sysAppBarSource, isNot(contains('windowManager.close()')));

    expect(popularSource, contains('Icons.search_rounded'));
    final appBarSource = popularSource.substring(
      popularSource.indexOf('Widget _buildMediaAppBar'),
      popularSource.indexOf('Widget _buildSpotlightBoard'),
    );
    expect(appBarSource, isNot(contains('Icons.refresh_rounded')));
    expect(appBarSource, contains('WindowControlInset'));
    expect(appBarSource, isNot(contains('Icons.minimize_rounded')));
    expect(appBarSource, isNot(contains('windowManager.minimize')));
    expect(appBarSource, isNot(contains('windowManager.maximize')));
    expect(appBarSource, isNot(contains('windowManager.close')));

    for (final source in [
      timelineSource,
      infoSource,
      searchSource,
      settingsSource,
    ]) {
      expect(
        source,
        contains(RegExp(r'WindowControlInset|KazumiDesktopHeaderTopRow')),
      );
    }
    expect(displayModeSource, contains('KazumiSettingsPageShell'));
    expect(storageErrorSource, contains('KazumiDesktopPageFrame'));
    expect(storageErrorSource, contains('_StorageErrorHeader'));
    expect(storageErrorSource, isNot(contains('GStorage')));
    expect(danmakuShieldSheetSource, contains('DanmakuShieldSettingsContent'));
    expect(danmakuShieldSheetSource, isNot(contains('SysAppBar')));
    expect(indexModuleSource, isNot(contains('SysAppBar')));
    expect(indexModuleSource, isNot(contains('appBar:')));
    final overlayControlsSource = windowControlsSource.substring(
      windowControlsSource.indexOf('class _OverlayWindowControls'),
      windowControlsSource.indexOf('class _CenteredMinimizeIcon'),
    );
    expect(overlayControlsSource, isNot(contains('tooltip:')));
    for (final marker in [
      'class WindowControlMetrics',
      'buttonWidth = 42',
      'controlWidth = buttonWidth * 3',
      'class WindowControlInset',
      'right: showControls ? WindowControlMetrics.controlWidth : 0',
    ]) {
      expect(windowControlsHostSource, contains(marker));
    }

    for (final source in [
      timelineSource,
      infoSource,
      searchSource,
      settingsSource,
    ]) {
      expect(
        source,
        contains(RegExp(r'WindowControlInset|KazumiDesktopHeaderTopRow')),
      );
      expect(source, isNot(contains('DesktopWindowControlHost')));
      expect(source, isNot(contains('const DesktopWindowControls()')));
      expect(
          source, isNot(contains('DesktopWindowControls(trailingSpacing: 0)')));
    }

    for (final source in [
      displayModeSource,
      storageErrorSource,
      danmakuShieldSheetSource,
      indexModuleSource,
    ]) {
      expect(source, isNot(contains('appBar: AppBar(')));
      expect(source, isNot(contains('SysAppBar')));
    }
  });

  test('continue watching stays before discover poster wall and can delete',
      () {
    final popularSource =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();

    final sliverSource = popularSource.substring(
      popularSource.indexOf('slivers: ['),
      popularSource.indexOf('Widget _buildRemoteError'),
    );
    expect(
      sliverSource.indexOf('_buildContinueWatchingStrip()'),
      lessThan(sliverSource.indexOf('_TrendCategoryBar(')),
    );
    expect(
      sliverSource.indexOf('_buildContinueWatchingStrip()'),
      lessThan(sliverSource.indexOf('_buildGrid(')),
    );
    expect(popularSource, contains('onDelete: ()'));
    expect(popularSource, contains('historyController.deleteHistory(history)'));

    expect(popularSource, contains('class _ContinueWatchingTile'));
    expect(popularSource, contains('required this.onDelete'));
    expect(popularSource, contains('onPointerDown'));
    expect(popularSource, contains('kSecondaryMouseButton'));
    expect(popularSource, contains('onSecondaryTap'));
    expect(popularSource, contains('onLongPressStart'));
    expect(popularSource, contains('showMenu<void>'));
    expect(popularSource, contains('PopupMenuItem<void>'));
    expect(popularSource, contains("Text('删除记录')"));
  });

  test('settings home is a responsive media preferences center', () {
    final source = File('lib/pages/my/my_page.dart').readAsStringSync();

    for (final marker in [
      'KazumiDesktopScrollFrame',
      'KazumiDesktopShell.mediaPageMaxWidth',
      '_SettingsSectionGrid',
      '_SettingsCategoryIndex',
      '_SettingsCategoryButton',
      '_SettingsHeader',
      '_SettingsSection',
      '_SettingsTile',
      'constraints.maxWidth >= 1040',
      r'\u8bbe\u7f6e',
      r'\u8d44\u6599\u5e93',
      r'\u64ad\u653e',
      r'\u5916\u89c2\u4e0e\u540c\u6b65',
      r'\u7ba1\u7406\u64ad\u653e\u3001\u8d44\u6599\u5e93',
    ]) {
      expect(source, contains(marker));
    }

    expect(source, isNot(contains('SysAppBar(title: Text')));
    expect(source, isNot(contains('appBar:')));
    expect(source, isNot(contains('MediaQuery.sizeOf(context).width;')));
  });

  test('theme picker offers curated media-library presets', () {
    final colorSource =
        File('lib/bean/settings/color_type.dart').readAsStringSync();
    final themeSettingsSource =
        File('lib/pages/settings/theme_settings_page.dart').readAsStringSync();

    for (final marker in [
      'class KazumiThemePreset',
      'defaultThemePreset',
      'storageValue',
      'fromStorageValue',
      '蓝调影院',
      '午夜霓虹',
      '胶片暖青',
      '樱桃暗场',
      '银幕极光',
      '0xFF3D6FB6',
      '0xFF00A7D8',
      '0xFFE7B95F',
      '0xFFD8577F',
      '0xFF8C7CF6',
    ]) {
      expect(colorSource, contains(marker));
    }

    expect(themeSettingsSource, contains('theme.storageValue'));
    expect(themeSettingsSource, contains('theme.label'));
    expect(themeSettingsSource, contains('setThemePreset(theme)'));
    expect(themeSettingsSource, isNot(contains("e['color']")));
    expect(themeSettingsSource, isNot(contains("e['label']")));

    for (final marker in [
      '青色',
      '蓝色',
      '黄色',
      '橙色',
      '深橙色',
      '剧院琥珀',
      '胶片青绿',
      '夜幕紫罗兰',
      '樱桃放映',
      '银幕靛蓝',
    ]) {
      expect(colorSource, isNot(contains(marker)));
    }
  });

  test('top-level media pages do not render fake back controls', () {
    final timelineSource =
        File('lib/pages/timeline/timeline_page.dart').readAsStringSync();
    final settingsSource = File('lib/pages/my/my_page.dart').readAsStringSync();
    final searchSource =
        File('lib/pages/search/search_page.dart').readAsStringSync();
    final infoSource = File('lib/pages/info/info_page.dart').readAsStringSync();

    expect(timelineSource, isNot(contains('required this.onBack')));
    expect(timelineSource,
        isNot(contains('onBack: () => onBackPressed(context)')));
    expect(
        timelineSource, isNot(contains('icon: const Icon(Icons.arrow_back),')));

    expect(settingsSource, contains('_SettingsHeader()'));
    expect(settingsSource, isNot(contains('_SettingsHeader(onBack:')));
    expect(settingsSource, isNot(contains('Icons.arrow_back_rounded')));

    expect(searchSource, contains('onBack: _leaveSearchPage'));
    expect(infoSource, contains('Icons.arrow_back'));
  });

  test('search page uses desktop media search controls', () {
    final source = File('lib/pages/search/search_page.dart').readAsStringSync();

    for (final marker in [
      '_SearchHeader',
      'onBack: _leaveSearchPage',
      '_SearchBar',
      '_SearchToolbar',
      '_SearchEmptyState',
      '_SearchErrorState',
      'SearchAnchor.bar',
      'MenuAnchor',
      'FilterChip',
      'KazumiDesktopShell.mediaPageMaxWidth',
      '_searchGridColumns',
      r'\u641c\u7d22',
      r'\u8fd4\u56de',
      r'\u6309\u70ed\u5ea6\u6392\u5e8f',
      r'\u9690\u85cf\u5df2\u770b',
    ]) {
      expect(source, contains(marker));
    }

    expect(source, contains('void _leaveSearchPage()'));
    expect(source, contains("Modular.to.navigate('/tab/popular/')"));
    expect(source, isNot(contains('FloatingActionButton')));
    expect(source, isNot(contains('showModalBottomSheet')));
  });

  test('tracking page has responsive content and a useful empty state', () {
    final source =
        File('lib/pages/collect/collect_page.dart').readAsStringSync();

    for (final marker in [
      '_CollectEmptyState',
      '_CollectPageActions',
      '_runCollectSync',
      '_collectGridColumns',
      'KazumiDesktopShell.mediaPageMaxWidth',
      "Modular.to.navigate('/tab/popular/')",
      r'\u8ffd\u756a',
      r'\u8fd8\u6ca1\u6709\u8ffd\u756a',
      r'\u4ece\u53d1\u73b0\u9875\u6253\u5f00\u4f5c\u54c1',
      r'\u53bb\u53d1\u73b0',
      r'\u5728\u770b',
      r'\u60f3\u770b',
      r'\u6401\u7f6e',
      r'\u770b\u8fc7',
      r'\u629b\u5f03',
    ]) {
      expect(source, contains(marker));
    }
    expect(source, isNot(contains('floatingActionButton:')));
    expect(source, isNot(contains('鏉╃晫')));
    expect(source, isNot(contains('閸戝棗')));
  });

  test('top-level initialization error page uses valid Chinese text', () {
    final source = File('lib/pages/index_module.dart').readAsStringSync();

    expect(source,
        anyOf(contains(r'\u521d\u59cb\u5316\u5931\u8d25'), contains('初始化失败')));
    expect(source, isNot(contains('鍒濆')));
  });

  test('image search page uses valid Chinese text', () {
    final source =
        File('lib/pages/search/image_search_page.dart').readAsStringSync();

    for (final marker in [
      r'\u56fe\u7247\u641c\u7d22',
      r'\u5f00\u59cb\u641c\u7d22',
      r'\u8bf7\u8f93\u5165\u56fe\u7247\u94fe\u63a5',
      r'\u8f93\u5165\u56fe\u7247\u94fe\u63a5\u540e\u9884\u89c8',
      r'\u8bf7\u68c0\u67e5\u94fe\u63a5\u662f\u5426\u6709\u6548',
      r'\u76f8\u4f3c\u5ea6',
      r'\u65f6\u95f4',
    ]) {
      expect(source, contains(marker));
    }

    for (final marker in ['寮€', '鍥剧墖', '閫夋嫨', '鐩镐技', '鏃堕棿']) {
      expect(source, isNot(contains(marker)));
    }
  });

  test('source selection sheet uses valid Chinese text', () {
    final source = File('lib/pages/info/source_sheet.dart').readAsStringSync();

    for (final marker in [
      (escaped: r'\u9a8c\u8bc1\u7801\u9a8c\u8bc1', text: '验证码验证'),
      (escaped: r'\u8bf7\u8f93\u5165\u9a8c\u8bc1\u7801', text: '请输入验证码'),
      (escaped: r'\u9a8c\u8bc1\u6210\u529f', text: '验证成功'),
      (escaped: r'\u6b63\u5728\u91cd\u65b0\u68c0\u7d22', text: '正在重新检索'),
      (escaped: r'\u81ea\u52a8\u9a8c\u8bc1\u4e2d', text: '自动验证中'),
      (escaped: r'\u9700\u8981\u9a8c\u8bc1\u7801\u9a8c\u8bc1', text: '需要验证码验证'),
      (escaped: r'\u7ed3\u679c\u4e0d\u51c6\u786e\uff1f', text: '结果不准确？'),
      (escaped: r'\u522b\u540d\u68c0\u7d22', text: '别名检索'),
      (escaped: r'\u624b\u52a8\u68c0\u7d22', text: '手动检索'),
      (escaped: r'\u89c6\u9891\u6765\u6e90', text: '视频来源'),
      (escaped: r'\u83b7\u53d6\u4e2d', text: '获取中'),
    ]) {
      expect(source, anyOf(contains(marker.escaped), contains(marker.text)));
    }

    for (final marker in [
      'Select Source',
      '楠岃瘉',
      '鍙栨秷',
      '鎵嬪姩',
      '鏆傛棤',
      '鑾峰彇',
    ]) {
      expect(source, isNot(contains(marker)));
    }
  });

  test('player settings page avoids placeholder fallback text', () {
    final source =
        File('lib/pages/settings/player_settings.dart').readAsStringSync();

    for (final marker in [
      (escaped: r'\u64ad\u653e\u8bbe\u7f6e', text: '播放设置'),
      (escaped: r'\u65e5\u5fd7\u7b49\u7ea7', text: '日志等级'),
      (escaped: r'\u9519\u8bef\u63d0\u793a', text: '错误提示'),
      (escaped: r'\u8c03\u8bd5\u6a21\u5f0f', text: '调试模式'),
      (escaped: r'\u672a\u77e5', text: '未知'),
    ]) {
      expect(source, anyOf(contains(marker.escaped), contains(marker.text)));
    }

    expect(source, isNot(contains('???')));
  });

  test('secondary settings pages use the unified glass settings shell', () {
    final shellSource =
        File('lib/bean/widget/settings_page_shell.dart').readAsStringSync();
    final pagePaths = [
      'lib/pages/settings/download_settings.dart',
      'lib/pages/settings/player_settings.dart',
      'lib/pages/settings/danmaku/danmaku_settings.dart',
      'lib/pages/settings/decoder_settings.dart',
      'lib/pages/settings/renderer_settings.dart',
      'lib/pages/settings/super_resolution_settings.dart',
      'lib/pages/settings/displaymode_settings.dart',
      'lib/pages/settings/keyboard_settings.dart',
      'lib/pages/settings/proxy/proxy_settings_page.dart',
    ];

    for (final marker in [
      'KazumiSettingsPageShell',
      'KazumiDesktopScrollFrame',
      'KazumiDesktopHeaderTopRow',
      'KazumiGlassSurface',
      'dtb.DragToMoveArea',
    ]) {
      expect(shellSource, contains(marker));
    }

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(source, contains('KazumiSettingsPageShell('), reason: path);
      expect(source, isNot(contains('SysAppBar')), reason: path);
      expect(source, isNot(contains('appBar:')), reason: path);
    }
  });

  test('proxy editor and disabled media cards avoid old desktop chrome', () {
    final proxyEditorSource =
        File('lib/pages/settings/proxy/proxy_editor_page.dart')
            .readAsStringSync();
    final cardSource =
        File('lib/bean/card/bangumi_card.dart').readAsStringSync();

    expect(proxyEditorSource, contains('KazumiSettingsPageShell('));
    expect(proxyEditorSource, contains('FilledButton.icon'));
    expect(proxyEditorSource, isNot(contains('SysAppBar')));
    expect(proxyEditorSource, isNot(contains('FloatingActionButton')));
    expect(cardSource, contains('编辑模式下不可打开详情'));
    expect(cardSource, isNot(contains('Edit mode')));
  });

  test('sync configuration pages use the shared settings shell', () {
    final pagePaths = [
      'lib/pages/webdav_editor/webdav_setting.dart',
      'lib/pages/webdav_editor/webdav_editor_page.dart',
      'lib/pages/bangumi/bangumi_setting.dart',
    ];

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(source, contains('KazumiSettingsPageShell('), reason: path);
      expect(source, isNot(contains('SysAppBar')), reason: path);
      expect(source, isNot(contains('FloatingActionButton')), reason: path);
    }
  });

  test('download and history pages use the media page frame', () {
    final pagePaths = [
      'lib/pages/download/download_page.dart',
      'lib/pages/history/history_page.dart',
    ];

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(source, contains('KazumiDesktopPageFrame'), reason: path);
      expect(source, contains('KazumiGlassSurface'), reason: path);
      expect(source, contains('WindowControlInset'), reason: path);
      expect(source, isNot(contains('SysAppBar')), reason: path);
    }
  });

  test('plugin and utility pages use the unified glass shell', () {
    final pagePaths = [
      'lib/pages/plugin_editor/plugin_editor_page.dart',
      'lib/pages/plugin_editor/plugin_shop_page.dart',
      'lib/pages/plugin_editor/plugin_view_page.dart',
      'lib/pages/plugin_editor/plugin_test_page.dart',
      'lib/pages/about/about_page.dart',
      'lib/pages/logs/logs_page.dart',
      'lib/pages/settings/danmaku/danmaku_shield_settings.dart',
    ];

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(source, contains('KazumiSettingsPageShell('), reason: path);
      expect(
        source,
        anyOf(contains('SettingsSectionCard'), contains('KazumiGlassSurface')),
        reason: path,
      );
      expect(source, isNot(contains('SysAppBar')), reason: path);
      expect(source, isNot(contains('appBar:')), reason: path);
    }

    final sheetSource =
        File('lib/pages/settings/danmaku/danmaku_shield_settings_sheet.dart')
            .readAsStringSync();
    expect(sheetSource, contains('DanmakuShieldSettingsContent'));
    expect(sheetSource, isNot(contains('SysAppBar')));
    expect(sheetSource, isNot(contains('appBar:')));
  });

  test('detail page keeps editorial episode-first media information layout',
      () {
    final source = File('lib/pages/info/info_page.dart').readAsStringSync();
    final tabViewSource =
        File('lib/pages/info/info_tabview.dart').readAsStringSync();
    final videoControllerSource =
        File('lib/pages/video/video_controller.dart').readAsStringSync();
    final videoPageSource =
        File('lib/pages/video/video_page.dart').readAsStringSync();

    for (final marker in [
      '_InfoHeaderBackground',
      'BangumiInfoCardV',
      '_DetailSegmentedTabBar',
      "bangumiItem.images['large']",
      '_leaveInfoPage',
      "Modular.to.navigate('/tab/popular/')",
      'Bangumi',
      'Modular.args.data as BangumiItem',
      'TabController(length: 3',
      'historyController.init()',
      'loadEpisodes',
      '_openEpisodeSourceSearch',
      '_latestPlayableHistoryForBangumi',
      'requestEpisodeSelection',
      '选集',
      '角色',
      '制作人员',
      '_SourceFloatingAction',
      'KazumiGlassSurface',
    ]) {
      expect(source, contains(marker));
    }
    expect(source, isNot(contains(r'\u8bc4\u8bba')));
    expect(source, isNot(contains(r'\u6982\u89c8')));
    expect(source, isNot(contains(r'\u5410\u69fd')));
    expect(source, isNot(contains('FloatingActionButton')));

    for (final marker in [
      'episodeListBody',
      '_EpisodeRoadSelector',
      '_EpisodeTile',
      'charactersListBody',
      'staffListBody',
      '选集',
    ]) {
      expect(tabViewSource, contains(marker));
    }
    expect(tabViewSource, isNot(contains('overviewBody')));
    expect(tabViewSource, isNot(contains('commentsListBody')));
    expect(tabViewSource, isNot(contains('CommentsCard')));
    expect(tabViewSource, isNot(contains('reviewPlaceholderBody')));
    expect(tabViewSource, isNot(contains('评论区暂不可用')));
    expect(videoControllerSource, contains('pendingEpisodeSelection'));
    expect(videoControllerSource, contains('requestEpisodeSelection'));
    expect(videoPageSource, contains('applyPendingEpisodeSelectionIfValid'));

    expect(source, contains('dtb.DragToMoveArea'));
    expect(source, contains('SliverAppBar.medium'));
  });
}
