import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
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
    if (KazumiDialog.observer.hasKazumiDialog) { KazumiDialog.dismiss(); return; }
    navigationBarState.updateSelectedIndex(0);
    Modular.to.navigate('/tab/popular/');
  }

  @override
  void initState() { super.initState(); navigationBarState = Provider.of<NavigationBarState>(context, listen: false); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; onBackPressed(context); }, child: Scaffold(appBar: const SysAppBar(title: Text('My'), needTopOffset: false), body: ListView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), children: [
      _section('Library', Icons.play_circle_outline_rounded, Colors.blue, [
        _nav(Icons.history_rounded, 'History', onTap: () => Modular.to.pushNamed('/settings/history/')),
        _nav(Icons.download_rounded, 'Downloads', onTap: () => Modular.to.pushNamed('/settings/download/')),
        _nav(Icons.dns_rounded, 'Download settings', onTap: () => Modular.to.pushNamed('/settings/download-settings')),
        _nav(Icons.extension_rounded, 'Rules', onTap: () => Modular.to.pushNamed('/settings/plugin/'), last: true),
      ]),
      const SizedBox(height: 16),
      _section('Player', Icons.play_circle_filled_rounded, Colors.purple, [
        _nav(Icons.display_settings_rounded, 'Player settings', onTap: () => Modular.to.pushNamed('/settings/player')),
        _nav(Icons.subtitles_rounded, 'Danmaku', onTap: () => Modular.to.pushNamed('/settings/danmaku/')),
        _nav(Icons.keyboard_rounded, 'Shortcuts', onTap: () => Modular.to.pushNamed('/settings/keyboard')),
        _nav(Icons.vpn_key_rounded, 'Proxy', onTap: () => Modular.to.pushNamed('/settings/proxy'), last: true),
      ]),
      const SizedBox(height: 16),
      _section('Appearance', Icons.palette_outlined, Colors.teal, [
        _nav(Icons.palette_rounded, 'Theme', onTap: () => Modular.to.pushNamed('/settings/theme')),
        _nav(Icons.pages_rounded, 'Interface', onTap: () => Modular.to.pushNamed('/settings/interface')),
        _nav(Icons.cloud_outlined, 'Sync', onTap: () => Modular.to.pushNamed('/settings/webdav/'), last: true),
      ]),
      const SizedBox(height: 16),
      _section('Other', Icons.more_horiz_rounded, Colors.orange, [
        _nav(Icons.info_outline_rounded, 'About', onTap: () => Modular.to.pushNamed('/settings/about/'), last: true),
      ]),
      const SizedBox(height: 32),
    ])));
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Material(color: Theme.of(context).colorScheme.surfaceContainerLow, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Row(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)), const SizedBox(width: 12), Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.2))])),
    const Divider(height: 1, indent: 16, endIndent: 16),
    ...children,
  ]))));

  Widget _nav(IconData icon, String title, {VoidCallback? onTap, bool last = false}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: scheme.onSurfaceVariant)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface))),
      Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant, size: 20),
    ])));
  }
}