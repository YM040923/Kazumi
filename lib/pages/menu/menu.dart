import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/widget/embedded_native_control_area.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/pages/router.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/ui_verification.dart';
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

  int getDefaultSelectedIndex() {
    final startupPage = !UiVerification.isEnabled
        ? GStorage.setting.get(
            SettingBoxKey.defaultStartupPage,
            defaultValue: '/tab/popular/',
          )
        : UiVerification.route;
    return switch (startupPage) {
      '/tab/timeline/' => 1,
      '/tab/collect/' => 2,
      '/tab/my/' => 3,
      _ => 0
    };
  }

  void updateSelectedIndex(int i) {
    _selectedIndex = i;
    notifyListeners();
  }

  void hideNavigate() {
    _isHide = true;
    notifyListeners();
  }

  void showNavigate() {
    _isHide = false;
    notifyListeners();
  }
}

class _ScaffoldMenu extends State<ScaffoldMenu> {
  late final NavigationBarState _navigationState;

  @override
  void initState() {
    super.initState();
    _navigationState = NavigationBarState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToIndex(_navigationState.selectedIndex);
    });
  }

  @override
  void dispose() {
    _navigationState.dispose();
    super.dispose();
  }

  void _navigateToIndex(int index) {
    Modular.to.navigate('/tab${menu.getPath(index)}/');
  }

  void _selectDestination(NavigationBarState state, int index) {
    state.updateSelectedIndex(index);
    _navigateToIndex(index);
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
      value: _navigationState,
      child: Consumer<NavigationBarState>(
          builder: (ctx, state, _) => OrientationBuilder(builder: (ctx, o) {
                state._isBottom = o == Orientation.portrait;
                return o != Orientation.portrait
                    ? _side(ctx, state)
                    : _bottom(ctx, state);
              })));

  Widget _bottom(BuildContext context, NavigationBarState state) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        body: const _ConstrainedRouterOutlet(),
        bottomNavigationBar: state.isHide
            ? const SizedBox(height: 0)
            : KazumiGlassSurface(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                blurSigma: 16,
                opacity: 0.78,
                showShadow: true,
                child: NavigationBar(
                    selectedIndex: state.selectedIndex,
                    backgroundColor: scheme.surface.withValues(alpha: 0.28),
                    surfaceTintColor: Colors.transparent,
                    height: 72,
                    animationDuration: const Duration(milliseconds: 400),
                    indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onDestinationSelected: (i) {
                      _selectDestination(state, i);
                    },
                    destinations: const [
                      NavigationDestination(
                          selectedIcon: Icon(Icons.home_rounded, size: 26),
                          icon: Icon(Icons.home_outlined, size: 26),
                          label: '发现'),
                      NavigationDestination(
                          selectedIcon: Icon(Icons.timeline_rounded, size: 26),
                          icon: Icon(Icons.timeline_outlined, size: 26),
                          label: '时间表'),
                      NavigationDestination(
                          selectedIcon: Icon(Icons.favorite_rounded, size: 26),
                          icon: Icon(Icons.favorite_outlined, size: 26),
                          label: '追番'),
                      NavigationDestination(
                          selectedIcon: Icon(Icons.settings_rounded, size: 26),
                          icon: Icon(Icons.settings_outlined, size: 26),
                          label: '设置'),
                    ])));
  }

  Widget _side(BuildContext context, NavigationBarState state) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        body: _ShellBackdrop(
          child: Row(children: [
            EmbeddedNativeControlArea(
                child: Visibility(
                    visible: !state.isHide,
                    child: _MediaSideBar(
                        selectedIndex: state.selectedIndex,
                        onDestinationSelected: (i) {
                          _selectDestination(state, i);
                        }))),
            const Expanded(child: _DesktopRouteSurface()),
          ]),
        ));
  }
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLow,
            scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
            scheme.tertiary.withValues(alpha: isDark ? 0.10 : 0.06),
            scheme.surface,
          ],
          stops: const [0, 0.34, 0.68, 1],
        ),
      ),
      child: child,
    );
  }
}

class _DesktopRouteSurface extends StatelessWidget {
  const _DesktopRouteSurface();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: KazumiGlassSurface(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            blurSigma: 20,
            opacity:
                Theme.of(context).brightness == Brightness.dark ? 0.68 : 0.82,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: const ClipRect(
                child: _ConstrainedRouterOutlet(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConstrainedRouterOutlet extends StatelessWidget {
  const _ConstrainedRouterOutlet();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
          child: const RouterOutlet(),
        );
      },
    );
  }
}

class _MediaSideBar extends StatelessWidget {
  const _MediaSideBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    _MediaNavDestination(
      label: '发现',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _MediaNavDestination(
      label: '时间表',
      icon: Icons.timeline_outlined,
      selectedIcon: Icons.timeline_rounded,
    ),
    _MediaNavDestination(
      label: '追番',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    _MediaNavDestination(
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '宽屏导航',
      child: SizedBox(
        width: KazumiDesktopShell.sidebarWidth,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: KazumiGlassSurface(
            borderRadius: BorderRadius.zero,
            blurSigma: 18,
            opacity:
                Theme.of(context).brightness == Brightness.dark ? 0.48 : 0.58,
            showShadow: false,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SidebarBrand(),
                    const SizedBox(height: 22),
                    _MediaNavCluster(
                      destinations: _destinations,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                    ),
                    const Spacer(),
                    _SidebarStatusDot(color: scheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaNavCluster extends StatelessWidget {
  const _MediaNavCluster({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<_MediaNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < destinations.length; index++) ...[
          _MediaNavButton(
            label: destinations[index].label,
            icon: destinations[index].icon,
            selectedIcon: destinations[index].selectedIcon,
            selected: selectedIndex == index,
            onPressed: () => onDestinationSelected(index),
          ),
          if (index != destinations.length - 1) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _MediaNavDestination {
  const _MediaNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Kazumi 媒体中心',
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: scheme.onPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _MediaNavButton extends StatelessWidget {
  const _MediaNavButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: KazumiDurations.fast,
                  left: selected ? 0 : -5,
                  top: 10,
                  bottom: 10,
                  child: AnimatedContainer(
                    duration: KazumiDurations.fast,
                    width: 3,
                    decoration: BoxDecoration(
                      color: selected ? scheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: KazumiDurations.fast,
                  width: 46,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 22,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarStatusDot extends StatelessWidget {
  const _SidebarStatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Kazumi',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.82),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
