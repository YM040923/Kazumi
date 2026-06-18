import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/widget/embedded_native_control_area.dart';
import 'package:kazumi/pages/router.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:provider/provider.dart';

class ScaffoldMenu extends StatefulWidget {
  const ScaffoldMenu({super.key});
  @override
  State<ScaffoldMenu> createState() => _ScaffoldMenu();
}

class NavigationBarState extends ChangeNotifier {
  late int _selectedIndex = getDefaultSelectedIndex();
  bool _isHide = false;
  bool _isBottom = false;
  int get selectedIndex => _selectedIndex;
  bool get isHide => _isHide;
  bool get isBottom => _isBottom;
  int getDefaultSelectedIndex() => switch (GStorage.setting.get(SettingBoxKey.defaultStartupPage, defaultValue: "/tab/popular/")) { '/tab/timeline/' => 1, '/tab/collect/' => 2, '/tab/my/' => 3, _ => 0 };
  void updateSelectedIndex(int i) { _selectedIndex = i; notifyListeners(); }
  void hideNavigate() { _isHide = true; notifyListeners(); }
  void showNavigate() { _isHide = false; notifyListeners(); }
}

class _ScaffoldMenu extends State<ScaffoldMenu> {
  final PageController _page = PageController();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(create: (_) => NavigationBarState(), child: Consumer<NavigationBarState>(builder: (ctx, state, _) => OrientationBuilder(builder: (ctx, o) { state._isBottom = o == Orientation.portrait; return o != Orientation.portrait ? _side(ctx, state) : _bottom(ctx, state); })));

  Widget _bottom(BuildContext context, NavigationBarState state) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(body: PageView.builder(physics: const NeverScrollableScrollPhysics(), controller: _page, itemCount: menu.size, itemBuilder: (_, __) => const RouterOutlet()), bottomNavigationBar: state.isHide ? const SizedBox(height: 0) : Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))]), child: NavigationBar(selectedIndex: state.selectedIndex, backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent, height: 72, animationDuration: const Duration(milliseconds: 400), indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), onDestinationSelected: (i) { state.updateSelectedIndex(i); Modular.to.navigate("/tab${menu.getPath(i)}/"); }, destinations: const [
      NavigationDestination(selectedIcon: Icon(Icons.home_rounded, size: 26), icon: Icon(Icons.home_outlined, size: 26), label: 'Discover'),
      NavigationDestination(selectedIcon: Icon(Icons.timeline_rounded, size: 26), icon: Icon(Icons.timeline_outlined, size: 26), label: 'Schedule'),
      NavigationDestination(selectedIcon: Icon(Icons.favorite_rounded, size: 26), icon: Icon(Icons.favorite_outlined, size: 26), label: 'Favorites'),
      NavigationDestination(selectedIcon: Icon(Icons.settings_rounded, size: 26), icon: Icon(Icons.settings_outlined, size: 26), label: 'Settings'),
    ])));
  }

  Widget _side(BuildContext context, NavigationBarState state) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(backgroundColor: scheme.surfaceContainerLow, body: Row(children: [
      EmbeddedNativeControlArea(child: Visibility(visible: !state.isHide, child: NavigationRail(backgroundColor: scheme.surfaceContainerLow, groupAlignment: 1.0, selectedIndex: state.selectedIndex, indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), labelType: NavigationRailLabelType.selected, leading: Padding(padding: const EdgeInsets.only(top: 8), child: FloatingActionButton(elevation: 0, heroTag: null, hoverElevation: 0, backgroundColor: scheme.surfaceContainerHighest, foregroundColor: scheme.onSurfaceVariant, onPressed: () => Modular.to.pushNamed('/search/'), child: const Icon(Icons.search_rounded, size: 22))), destinations: const [
        NavigationRailDestination(selectedIcon: Icon(Icons.home_rounded, size: 24), icon: Icon(Icons.home_outlined, size: 24), label: Text('Discover')),
        NavigationRailDestination(selectedIcon: Icon(Icons.timeline_rounded, size: 24), icon: Icon(Icons.timeline_outlined, size: 24), label: Text('Schedule')),
        NavigationRailDestination(selectedIcon: Icon(Icons.favorite_rounded, size: 24), icon: Icon(Icons.favorite_border, size: 24), label: Text('Favorites')),
        NavigationRailDestination(selectedIcon: Icon(Icons.settings_rounded, size: 24), icon: Icon(Icons.settings_outlined, size: 24), label: Text('Settings')),
      ], onDestinationSelected: (i) { state.updateSelectedIndex(i); Modular.to.navigate("/tab${menu.getPath(i)}/"); }))),
      Expanded(child: Container(decoration: BoxDecoration(color: scheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(-4, 0))]), child: ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)), child: PageView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: menu.size, itemBuilder: (_, __) => const RouterOutlet())))),
    ]));
  }
}