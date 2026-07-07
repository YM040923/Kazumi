# Kazumi Desktop UI System Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Kazumi's Flutter desktop UI foundation so every major page responds correctly to window resizing and follows one coherent media-workspace design system.

**Architecture:** Add a shared adaptive layout layer under `lib/design/`, migrate the existing shell and pages onto that layer, then redesign high-risk panels and sparse pages. Keep controllers, routes, storage, playback, rules, and parser behavior unchanged.

**Tech Stack:** Flutter Material 3, existing `KazumiTheme`, existing `KazumiDesktopPageFrame`, `flutter_mobx`, `flutter_modular`, widget tests, and Windows debug build verification.

---

## Spec Reference

Use this spec as the source of truth:

- `docs/superpowers/specs/2026-06-16-kazumi-desktop-ui-system-redesign.md`

## Scope Check

This plan covers Flutter UI structure only. It intentionally excludes playback core, parser/rule behavior, download internals, and database schema changes.

Because the current worktree already contains partially completed UI changes, each task must read current files before editing and must not revert unrelated user or prior-agent changes.

## File Structure

- Create `lib/design/adaptive_layout.dart`
  - Defines `KazumiWindowClass`, `KazumiPageMetrics`, and helpers for content width, columns, gutters, and dialog sizing.

- Modify `lib/design/desktop_layout.dart`
  - Delegates existing frame behavior to the adaptive metrics while preserving current call sites.

- Modify `lib/pages/menu/menu.dart`
  - Makes the shell provide stable page constraints, navigation rail behavior, and resize-safe content.

- Modify `lib/pages/popular/popular_layout.dart`
  - Moves Discover grid sizing onto the shared adaptive metrics.

- Modify `lib/pages/popular/popular_page.dart`
  - Adopts shared metrics without changing Discover's approved visual direction.

- Modify `lib/pages/info/info_page.dart`
  - Reworks Detail header, tab behavior, and source panel constraints around shared metrics.

- Modify `lib/pages/info/source_sheet.dart`
  - Converts the desktop source selector from a large bottom sheet into a desktop source panel.

- Modify `lib/pages/timeline/timeline_page.dart`
  - Replaces scattered width math with responsive schedule-grid behavior.

- Modify `lib/pages/my/my_page.dart`
  - Converts Settings into a responsive settings center and improves Tracking empty/content states where owned by this page.

- Create or extend tests:
  - `test/ui/adaptive_layout_test.dart`
  - `test/ui/popular_spotlight_rotation_test.dart`
  - `test/ui/bangumi_info_card_test.dart`
  - `test/ui/source_sheet_components_test.dart`
  - `test/ui/localization_source_test.dart`

## Task 1: Adaptive Layout Foundation

**Files:**
- Create: `lib/design/adaptive_layout.dart`
- Modify: `lib/design/desktop_layout.dart`
- Test: `test/ui/adaptive_layout_test.dart`

- [ ] **Step 1: Write adaptive layout tests**

Create `test/ui/adaptive_layout_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/design/adaptive_layout.dart';

void main() {
  test('window classes map desktop widths consistently', () {
    expect(KazumiWindowClass.forWidth(640), KazumiWindowClass.compact);
    expect(KazumiWindowClass.forWidth(900), KazumiWindowClass.medium);
    expect(KazumiWindowClass.forWidth(1280), KazumiWindowClass.wide);
    expect(KazumiWindowClass.forWidth(1680), KazumiWindowClass.ultrawide);
  });

  test('page metrics reserve gutters and cap readable content', () {
    final compact = KazumiPageMetrics.fromViewport(width: 700, height: 720);
    expect(compact.gutter, 16);
    expect(compact.contentWidth, 668);
    expect(compact.windowClass, KazumiWindowClass.compact);

    final wide = KazumiPageMetrics.fromViewport(width: 1500, height: 960);
    expect(wide.gutter, 32);
    expect(wide.contentWidth, 1180);
    expect(wide.windowClass, KazumiWindowClass.ultrawide);
  });

  test('grid column helper keeps media pages responsive', () {
    expect(KazumiPageMetrics.fromViewport(width: 720, height: 720).mediaColumns, 2);
    expect(KazumiPageMetrics.fromViewport(width: 980, height: 860).mediaColumns, 3);
    expect(KazumiPageMetrics.fromViewport(width: 1280, height: 860).mediaColumns, 5);
  });
}
```

- [ ] **Step 2: Run the failing test**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/adaptive_layout_test.dart
```

Expected: FAIL because `lib/design/adaptive_layout.dart` does not exist.

- [ ] **Step 3: Implement adaptive metrics**

Create `lib/design/adaptive_layout.dart`:

```dart
import 'dart:math' as math;

enum KazumiWindowClass {
  compact,
  medium,
  wide,
  ultrawide;

  static KazumiWindowClass forWidth(double width) {
    if (width >= 1440) return KazumiWindowClass.ultrawide;
    if (width >= 1100) return KazumiWindowClass.wide;
    if (width >= 760) return KazumiWindowClass.medium;
    return KazumiWindowClass.compact;
  }
}

class KazumiPageMetrics {
  const KazumiPageMetrics({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.windowClass,
    required this.gutter,
    required this.contentWidth,
  });

  final double viewportWidth;
  final double viewportHeight;
  final KazumiWindowClass windowClass;
  final double gutter;
  final double contentWidth;

  bool get isCompact => windowClass == KazumiWindowClass.compact;
  bool get isMediumOrLarger => windowClass.index >= KazumiWindowClass.medium.index;
  bool get isWideOrLarger => windowClass.index >= KazumiWindowClass.wide.index;

  int get mediaColumns {
    return switch (windowClass) {
      KazumiWindowClass.compact => 2,
      KazumiWindowClass.medium => 3,
      KazumiWindowClass.wide => 5,
      KazumiWindowClass.ultrawide => 5,
    };
  }

  double get dialogMaxWidth {
    return switch (windowClass) {
      KazumiWindowClass.compact => viewportWidth,
      KazumiWindowClass.medium => math.min(720, viewportWidth - gutter * 2),
      KazumiWindowClass.wide => math.min(860, viewportWidth - gutter * 2),
      KazumiWindowClass.ultrawide => math.min(920, viewportWidth - gutter * 2),
    };
  }

  double get dialogMaxHeight {
    return switch (windowClass) {
      KazumiWindowClass.compact => viewportHeight,
      _ => viewportHeight * 0.82,
    };
  }

  factory KazumiPageMetrics.fromViewport({
    required double width,
    required double height,
    double maxContentWidth = 1180,
  }) {
    final windowClass = KazumiWindowClass.forWidth(width);
    final gutter = switch (windowClass) {
      KazumiWindowClass.compact => 16.0,
      KazumiWindowClass.medium => 24.0,
      KazumiWindowClass.wide => 28.0,
      KazumiWindowClass.ultrawide => 32.0,
    };
    final availableWidth = math.max(0.0, width - gutter * 2);
    return KazumiPageMetrics(
      viewportWidth: width,
      viewportHeight: height,
      windowClass: windowClass,
      gutter: gutter,
      contentWidth: math.min(maxContentWidth, availableWidth),
    );
  }
}
```

- [ ] **Step 4: Update the desktop frame to use metrics**

Modify `lib/design/desktop_layout.dart` so `KazumiDesktopPageFrame.build` computes `KazumiPageMetrics.fromViewport(width: constraints.maxWidth, height: MediaQuery.sizeOf(context).height, maxContentWidth: maxWidth)` and uses `metrics.gutter` when no explicit `horizontalPadding` is passed.

Keep the public constructor compatible by changing `horizontalPadding` to nullable:

```dart
final double? horizontalPadding;
```

Then inside `build` use:

```dart
final metrics = KazumiPageMetrics.fromViewport(
  width: constraints.maxWidth,
  height: MediaQuery.sizeOf(context).height,
  maxContentWidth: maxWidth,
);
final effectivePadding = horizontalPadding ?? metrics.gutter;
final availableWidth = math.max(0.0, constraints.maxWidth - effectivePadding * 2);
final frameWidth = math.min(maxWidth, availableWidth);
```

- [ ] **Step 5: Run adaptive tests**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/adaptive_layout_test.dart
```

Expected: PASS.

## Task 2: Shell Resize Contract

**Files:**
- Modify: `lib/pages/menu/menu.dart`
- Test: `test/ui/localization_source_test.dart`

- [ ] **Step 1: Inspect current shell behavior**

Run:

```powershell
rg -n "LayoutBuilder|MediaQuery|KazumiDesktopShell|NavigationRail|NavigationBar|ChangeNotifierProvider" lib/pages/menu/menu.dart
```

Expected: output shows the desktop side rail and mobile bottom navigation paths.

- [ ] **Step 2: Add a shell-level content constraint**

In `lib/pages/menu/menu.dart`, keep the existing navigation state and route behavior. Wrap the desktop content region in a `LayoutBuilder` that passes the actual remaining width after the rail to child pages. Do not add hard-coded page widths inside the shell.

The shell should continue to use:

```dart
KazumiDesktopShell.sidebarWidth
```

for rail width only. Page max widths belong to page frames, not the shell.

- [ ] **Step 3: Preserve provider lifecycle**

Ensure `_side` uses:

```dart
ChangeNotifierProvider<NavigationBarState>.value(
  value: state,
  child: ...
)
```

Expected: no duplicate `NavigationBarState` instance is created during resize.

- [ ] **Step 4: Run source guard tests**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/localization_source_test.dart
```

Expected: PASS or fail only on intentional source assertions that must be updated to the new shared adaptive file names.

## Task 3: Discover Migration Without Redesign

**Files:**
- Modify: `lib/pages/popular/popular_layout.dart`
- Modify: `lib/pages/popular/popular_page.dart`
- Test: `test/ui/popular_spotlight_rotation_test.dart`

- [ ] **Step 1: Move grid sizing to adaptive metrics**

Update `popularPosterGridColumnCount` in `lib/pages/popular/popular_layout.dart` to depend on the same thresholds as `KazumiWindowClass`:

```dart
int popularPosterGridColumnCount(double contentWidth) {
  if (contentWidth >= 1100) return 5;
  if (contentWidth >= 760) return 3;
  return 2;
}
```

- [ ] **Step 2: Keep Discover visual direction stable**

In `lib/pages/popular/popular_page.dart`, only replace local width assumptions with `KazumiPageMetrics`. Do not change copy, poster sizes, hero composition, category labels, or the already-approved first screen unless a resize bug requires it.

- [ ] **Step 3: Run Discover tests**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/popular_spotlight_rotation_test.dart
```

Expected: PASS after updating any column-count assertions to the new shared thresholds.

## Task 4: Detail Page Responsive Recomposition

**Files:**
- Modify: `lib/pages/info/info_page.dart`
- Modify: `lib/bean/card/bangumi_info_card.dart`
- Test: `test/ui/bangumi_info_card_test.dart`

- [ ] **Step 1: Capture current detail layout risks**

Run:

```powershell
rg -n "width: 178|width: 228|height: 264|kTextTabBarHeight|SliverAppBar|LayoutBuilder|Wrap" lib/pages/info/info_page.dart lib/bean/card/bangumi_info_card.dart
```

Expected: output identifies fixed poster/action widths and fixed tab/header relationships.

- [ ] **Step 2: Recompose header by window class**

In `lib/pages/info/info_page.dart`, use `KazumiPageMetrics` to choose:

- compact: vertical stack.
- medium: poster plus text, actions below.
- wide and ultrawide: poster, text, action panel in a row.

Keep existing callbacks for start watching, favorite status, and Bangumi link.

- [ ] **Step 3: Stabilize tab layout**

Keep `TabController` and current `InfoTabView`. Remove assumptions that tab visibility depends on one fixed expanded header height. The tab bar must remain reachable after resize at 760 x 720, 1280 x 860, and 1650 x 960.

- [ ] **Step 4: Run detail card tests**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/bangumi_info_card_test.dart
```

Expected: PASS after updating expected text only if the visual contract changed.

## Task 5: Desktop Source Selection Panel

**Files:**
- Modify: `lib/pages/info/info_page.dart`
- Modify: `lib/pages/info/source_sheet.dart`
- Modify: `lib/bean/widget/source_sheet_components.dart`
- Test: `test/ui/source_sheet_components_test.dart`

- [ ] **Step 1: Replace desktop bottom-sheet sizing with adaptive dialog metrics**

In `InfoPage`, compute:

```dart
final metrics = KazumiPageMetrics.fromViewport(
  width: MediaQuery.sizeOf(context).width,
  height: MediaQuery.sizeOf(context).height,
);
```

Use `metrics.dialogMaxWidth` and `metrics.dialogMaxHeight` for desktop source selection.

- [ ] **Step 2: Keep compact bottom-sheet behavior**

For `metrics.isCompact`, keep the current bottom-sheet presentation so small windows still behave naturally.

- [ ] **Step 3: Rebuild the source selector body as a desktop panel**

In `source_sheet.dart`, structure the desktop body as:

- Top: source tabs/list and status indicators.
- Middle: result list.
- Bottom: alias search and manual search actions.

Keep the existing source query and video navigation logic exactly where it is.

- [ ] **Step 4: Run source component tests**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/source_sheet_components_test.dart
```

Expected: PASS.

## Task 6: Timeline Responsive Schedule Board

**Files:**
- Modify: `lib/pages/timeline/timeline_page.dart`
- Test: add focused helper tests if timeline sizing helpers are extracted.

- [ ] **Step 1: Identify local width math**

Run:

```powershell
rg -n "LayoutBreakpoint|crossAxisCount|childAspectRatio|SliverGrid|TabBar|MediaQuery" lib/pages/timeline/timeline_page.dart
```

Expected: output shows the current width-dependent grid code.

- [ ] **Step 2: Extract schedule columns**

Create a private helper in `timeline_page.dart`:

```dart
int _timelineColumnCount(KazumiWindowClass windowClass) {
  return switch (windowClass) {
    KazumiWindowClass.compact => 1,
    KazumiWindowClass.medium => 2,
    KazumiWindowClass.wide => 3,
    KazumiWindowClass.ultrawide => 3,
  };
}
```

- [ ] **Step 3: Anchor weekday tabs near the title**

Move weekday navigation into the same content frame as the page title. It must not stretch across the full raw window width on ultrawide screens.

- [ ] **Step 4: Build and visually inspect**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat build windows --debug
```

Expected: build succeeds. Then inspect Timeline at 760 x 720, 1280 x 860, and 1650 x 960.

## Task 7: Tracking And Settings Information Architecture

**Files:**
- Modify: `lib/pages/my/my_page.dart`
- Test: `test/ui/localization_source_test.dart`

- [ ] **Step 1: Split Settings page into overview and category panes**

In `my_page.dart`, use `KazumiPageMetrics`:

- compact: single-column settings list.
- medium: two-column overview cards.
- wide/ultrawide: left category index and right selected category preview.

Do not move route destinations; only change layout composition.

- [ ] **Step 2: Add a useful Tracking empty state**

For empty tracking tabs, replace lone centered text with:

- title: `还没有追番`
- body: `从发现页打开作品并加入追番后，会出现在这里。`
- action: `去发现`

The action navigates to `/tab/popular/` using the existing `Modular.to.navigate` pattern.

- [ ] **Step 3: Align floating actions to content frame**

Move refresh/edit floating buttons so they align to the adaptive page frame instead of the raw window edge.

- [ ] **Step 4: Run localization/source guards**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/localization_source_test.dart
```

Expected: PASS after updating assertions for any new Chinese UI strings.

## Task 8: Visual Verification Pass

**Files:**
- No required source edits unless verification finds defects.

- [ ] **Step 1: Format changed Dart files**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\dart.bat format lib/design lib/pages/menu lib/pages/popular lib/pages/info lib/pages/timeline lib/pages/my test/ui
```

Expected: formatter exits 0.

- [ ] **Step 2: Run focused tests**

Run:

```powershell
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat test test/ui/adaptive_layout_test.dart test/ui/popular_spotlight_rotation_test.dart test/ui/bangumi_info_card_test.dart test/ui/source_sheet_components_test.dart test/ui/localization_source_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Build Windows debug app**

Close any running `kazumi.exe`, then run:

```powershell
Get-Process | Where-Object { $_.ProcessName -like '*kazumi*' } | Stop-Process
& F:\meihua\.toolchains\flutter-3.41.9\flutter\bin\flutter.bat build windows --debug
```

Expected: build succeeds and writes `build\windows\x64\runner\Debug\kazumi.exe`.

- [ ] **Step 4: Manual window verification**

Open the debug executable and verify:

- 760 x 720: Discover, Detail, Source Selection, Timeline, Tracking, Settings.
- 1280 x 860: Discover, Detail, Source Selection, Timeline, Tracking, Settings.
- 1650 x 960: Discover, Detail, Source Selection, Timeline, Tracking, Settings.

Expected: no clipped controls, no unreadable text, no fixed-width content stuck to the left with unusable empty space, and no modal that becomes impossible to dismiss.

## Self-Review

- Spec coverage: Tasks 1-2 cover shell and responsiveness. Tasks 3-7 cover Discover, Detail, Source Selection, Timeline, Tracking, and Settings. Task 8 covers verification.
- Placeholder scan: No placeholder task remains; every task has concrete files, commands, and expected results.
- Type consistency: `KazumiWindowClass` and `KazumiPageMetrics` are introduced in Task 1 and reused consistently in later tasks.


