import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:provider/provider.dart';

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
    final sections = _settingsSections(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBackPressed(context);
      },
      child: Scaffold(
        appBar: const SysAppBar(needTopOffset: false),
        body: WindowControlInset(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 18),
              children: [
                KazumiDesktopPageFrame(
                  maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useWideLayout = constraints.maxWidth >= 1040;
                      final content = _SettingsSectionGrid(
                        sections: sections,
                        useWideLayout: useWideLayout,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SettingsHeader(),
                          const SizedBox(height: 18),
                          if (useWideLayout)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 248,
                                  child: _SettingsCategoryIndex(
                                    sections: sections,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(child: content),
                              ],
                            )
                          else ...[
                            _SettingsCategoryIndex(sections: sections),
                            const SizedBox(height: 14),
                            content,
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_SettingsSectionData> _settingsSections(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return [
      _SettingsSectionData(
        title: '\u8d44\u6599\u5e93',
        subtitle: '管理历史、下载与规则来源。',
        icon: Icons.video_library_rounded,
        color: scheme.primary,
        tiles: [
          _SettingsTileData(
            icon: Icons.history_rounded,
            title: '观看历史',
            subtitle: '查看和管理继续观看记录。',
            route: '/settings/history/',
          ),
          _SettingsTileData(
            icon: Icons.download_rounded,
            title: '下载管理',
            subtitle: '查看离线缓存和下载任务。',
            route: '/settings/download/',
          ),
          _SettingsTileData(
            icon: Icons.dns_rounded,
            title: '下载设置',
            subtitle: '配置并发、缓存和下载目录。',
            route: '/settings/download-settings',
          ),
          _SettingsTileData(
            icon: Icons.extension_rounded,
            title: '规则管理',
            subtitle: '安装、更新和编辑播放规则。',
            route: '/settings/plugin/',
          ),
        ],
      ),
      _SettingsSectionData(
        title: '\u64ad\u653e',
        subtitle: '调整播放器、弹幕、快捷键和代理。',
        icon: Icons.play_circle_rounded,
        color: scheme.secondary,
        tiles: [
          _SettingsTileData(
            icon: Icons.display_settings_rounded,
            title: '播放设置',
            subtitle: '调整播放行为、渲染器和错误提示。',
            route: '/settings/player',
          ),
          _SettingsTileData(
            icon: Icons.subtitles_rounded,
            title: '弹幕设置',
            subtitle: '配置弹幕样式、屏蔽词和同步。',
            route: '/settings/danmaku/',
          ),
          _SettingsTileData(
            icon: Icons.keyboard_rounded,
            title: '快捷键',
            subtitle: '自定义播放器和窗口操作快捷键。',
            route: '/settings/keyboard',
          ),
          _SettingsTileData(
            icon: Icons.vpn_key_rounded,
            title: '代理设置',
            subtitle: '配置网络请求和解析播放源代理。',
            route: '/settings/proxy',
          ),
        ],
      ),
      _SettingsSectionData(
        title: '\u5916\u89c2\u4e0e\u540c\u6b65',
        subtitle: '统一主题、界面和多端同步体验。',
        icon: Icons.palette_rounded,
        color: scheme.tertiary,
        tiles: [
          _SettingsTileData(
            icon: Icons.color_lens_rounded,
            title: '外观主题',
            subtitle: '切换主题色、深浅模式和媒体库预设。',
            route: '/settings/theme',
          ),
          _SettingsTileData(
            icon: Icons.dashboard_customize_rounded,
            title: '界面设置',
            subtitle: '设置启动页面、导航和窗口外观。',
            route: '/settings/interface',
          ),
          _SettingsTileData(
            icon: Icons.cloud_sync_rounded,
            title: 'WebDAV 同步',
            subtitle: '同步追番、历史和应用数据。',
            route: '/settings/webdav/',
          ),
        ],
      ),
      _SettingsSectionData(
        title: '其他',
        subtitle: '版本、说明与应用信息。',
        icon: Icons.more_horiz_rounded,
        color: scheme.outline,
        tiles: [
          _SettingsTileData(
            icon: Icons.info_outline_rounded,
            title: '关于 Kazumi',
            subtitle: '查看版本、开源信息和项目说明。',
            route: '/settings/about/',
          ),
        ],
      ),
    ];
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KazumiGlassSurface(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u8bbe\u7f6e',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\u7ba1\u7406\u64ad\u653e\u3001\u8d44\u6599\u5e93、外观与同步等偏好。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }
}

class _SettingsSectionGrid extends StatelessWidget {
  const _SettingsSectionGrid({
    required this.sections,
    required this.useWideLayout,
  });

  final List<_SettingsSectionData> sections;
  final bool useWideLayout;

  @override
  Widget build(BuildContext context) {
    if (!useWideLayout) {
      return Column(
        children: [
          for (final section in sections) ...[
            _SettingsSection(section: section),
            if (section != sections.last) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: [
        for (final section in sections)
          SizedBox(
            width: 424,
            child: _SettingsSection(section: section),
          ),
      ],
    );
  }
}

class _SettingsCategoryIndex extends StatelessWidget {
  const _SettingsCategoryIndex({
    required this.sections,
  });

  final List<_SettingsSectionData> sections;

  @override
  Widget build(BuildContext context) {
    return KazumiGlassSurface(
      padding: const EdgeInsets.all(10),
      showShadow: false,
      child: Wrap(
        direction: Axis.vertical,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final section in sections)
            _SettingsCategoryButton(section: section),
        ],
      ),
    );
  }
}

class _SettingsCategoryButton extends StatelessWidget {
  const _SettingsCategoryButton({
    required this.section,
  });

  final _SettingsSectionData section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 220,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: section.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: section.color.withValues(alpha: 0.16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(section.icon, size: 18, color: section.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.section,
  });

  final _SettingsSectionData section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KazumiGlassSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, size: 20, color: section.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      section.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tile in section.tiles) _SettingsTile(tile: tile),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.tile,
  });

  final _SettingsTileData tile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Modular.to.pushNamed(tile.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(tile.icon, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tile.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionData {
  const _SettingsSectionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tiles,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_SettingsTileData> tiles;
}

class _SettingsTileData {
  const _SettingsTileData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
