# Kazumi Desktop UI System Redesign

## Objective

Redesign Kazumi's Flutter desktop UI as a coherent Windows media-library application. The work must fix the current responsive-layout failures first, then unify the visual language across Discover, Detail, Source Selection, Timeline, Tracking, and Settings.

This replaces the earlier page-by-page beautification approach. Discover can remain the visual reference point, but the application needs a stronger shell, breakpoint model, and page contract before more polish is useful.

## Evidence

The redesign is grounded in the screenshots supplied on 2026-06-16:

- Detail page: dark immersive layout with poster, metadata, action stack, tabs, summary card, and tags.
- Source selection: large desktop modal based on a mobile-style bottom sheet.
- Timeline page: light schedule board with weekday tabs and loose grid cards.
- Tracking page: mostly empty light page with tabs spread across the full window.
- Settings page: light settings hub with cards concentrated on the left and excessive empty space on the right.

## Product Direction

Kazumi should feel like a desktop media workspace rather than a phone UI stretched onto a wide screen. The app should keep a quiet, utility-first surface, with richer media treatment only where it helps selection and playback.

The design language is:

- Dense enough for repeated use.
- Calm enough for long browsing sessions.
- Media-forward on Discover and Detail.
- Tool-like and predictable in Settings, Tracking, Timeline, and Source Selection.
- Responsive from compact desktop windows to ultrawide screens.

## Non-Goals

- Do not change playback engines, parsers, rules, downloads, or database fields.
- Do not introduce a landing page or marketing-style hero page.
- Do not redesign every settings subpage before the shell and page frame are fixed.
- Do not continue dark-mode/detail-page experimentation until the global responsive contract exists.

## Core Problems

### 1. Layout Responsiveness

Several screens behave like fixed canvases. Wide windows create large empty zones, while smaller windows do not consistently reflow content. This causes the user's reported "internal UI cannot respond after window resizing" issue.

The root cause is scattered layout logic: pages use local `LayoutBuilder`, fixed widths, fixed modal heights, and page-specific max widths instead of a shared responsive model.

### 2. Visual Fragmentation

Discover, Detail, Timeline, Tracking, and Settings currently look like different products. Dark immersive detail can stay, but it needs a rule: it is a focus mode for a selected title, not the default app surface.

### 3. Desktop Interaction Mismatch

The source selector uses a large bottom sheet pattern that feels mobile. On desktop it should be an efficient selection panel with visible source state, result density, and search fallbacks.

### 4. Empty And Sparse States

Tracking and Settings show large empty regions. Empty states need clear next actions. Settings needs a two-pane information architecture on wide windows.

## Design Principles

1. Responsive first, polish second.
2. One shell, many pages.
3. Desktop panels over oversized bottom sheets.
4. Media-rich where browsing benefits; quiet utility where configuration benefits.
5. Preserve existing app behavior unless the UI contract requires a safer wrapper.
6. Do not nest cards inside decorative cards.
7. Avoid fixed-width page bodies unless the content type is explicitly bounded.

## Breakpoint Model

Create a shared breakpoint model with four layout classes:

- `compact`: under 760 px content width. Single-column, collapsed actions, vertical cards.
- `medium`: 760-1099 px. Two-column where useful, compact media heroes.
- `wide`: 1100-1439 px. Primary desktop layout.
- `ultrawide`: 1440 px and above. Centered content plus optional secondary panels.

The app shell must expose page metrics so individual pages do not recalculate window behavior differently.

## Global Shell Contract

The shell owns:

- Navigation rail width and selection state.
- Page background.
- Window button area and drag region.
- Safe page padding.
- Content max width.
- Responsive class.
- Scroll behavior.

Each page receives a consistent content frame and should only decide its own inner composition.

## Page Contracts

### Discover

Discover is close to acceptable. It should be migrated into the shared page frame without large visual changes.

Required behavior:

- Hero stays media-forward.
- Poster grid reflows by shared breakpoints.
- Horizontal spotlight rail scrolls only when it actually overflows.
- Continue-watching and trend sections use the same section header rhythm as other pages.

### Detail

Detail is the only page allowed to use a dark immersive focus surface by default.

Required behavior:

- Wide layout: poster left, metadata and summary center, actions right.
- Medium layout: poster and metadata top, actions inline below title.
- Compact layout: poster and title stack vertically; actions become full-width.
- Tabs remain visible but must not depend on a fixed header height.
- Summary/tags card must reflow instead of clipping or leaving large empty zones.
- Top right actions must use stable desktop button placement.

### Source Selection

Replace the oversized bottom sheet pattern on desktop.

Required behavior:

- Desktop: centered panel or right-side panel, max width 860-960, max height 80 percent of window.
- Panel structure: source tabs/list, result list, fallback actions.
- Result cards use compact list density.
- Empty/loading/error states stay within the panel body.
- Mobile/tablet can still use a bottom sheet.

### Timeline

Timeline should become a responsive schedule board.

Required behavior:

- Wide: 3-column or 4-column schedule grid based on content width.
- Medium: 2-column grid.
- Compact: date-grouped vertical list.
- Weekday navigation must remain close to page title, not drift across the whole viewport.
- Cards should have stable poster dimensions and no excessive vertical whitespace.

### Tracking

Tracking needs a real empty state and content-state layout.

Required behavior:

- Empty state includes title, explanation, and action to Discover.
- Tabs should be anchored in a max-width content frame.
- When populated, each status tab uses a responsive media list/grid.
- Floating refresh/action buttons should align with the page frame, not the raw window edge.

### Settings

Settings should become a desktop settings center.

Required behavior:

- Wide: left category index, right selected settings group.
- Medium: two-column overview cards.
- Compact: single-column category list.
- No large unused right half on wide windows.
- Quick settings stay as shortcuts, not as the main page structure.

## Visual System

Use a unified light application surface:

- App background: neutral off-white, not overly warm.
- Navigation rail: quiet surface with clear selected indicator.
- Cards: radius 8-12, low border, minimal shadow.
- Buttons: filled for primary actions, outlined or tonal for secondary actions.
- Dark immersive detail: deep green/black is allowed but must use the same spacing and component rhythm.

Avoid:

- One-note beige/brown pages.
- Unbounded dark overlays that reduce text contrast.
- Huge cards that contain only a few controls.
- Floating content islands without a layout reason.

## Accessibility And Usability

- All interactive targets should be at least 40 x 40 px on desktop.
- Text must not overflow or be clipped at compact widths.
- Empty states must be reachable by keyboard and screen readers.
- Dialogs/panels must support Escape/back dismissal where existing behavior permits.
- Resizing the app should not require navigation reload to settle layout.

## Verification Matrix

Every UI phase must verify:

- 760 x 720 window.
- 1280 x 860 window.
- 1650 x 960 window.
- Discover to Detail to Source Selection flow.
- Timeline page.
- Tracking empty state.
- Settings overview.
- At least one modal/panel open during resize.

Automated checks must include focused layout helper tests and at least one widget/source test per changed page group.


