# Kazumi Flutter Cinematic Discover UI Design

## Goal

Improve the existing Flutter Kazumi app with a first-phase "Fluent Cinema Shell" polish pass focused on the real user-facing product.

The first phase targets the homepage, anime detail page, and play-entry flow. The app should feel closer to a modern Windows media client on desktop while still adapting naturally to mobile and tablet layouts.

## Research Inputs

This design is informed by current Windows and media-client patterns:

- Microsoft Mica guidance: use subtle foundation materials for long-lived app surfaces and hierarchy, not decorative blur everywhere.
  <https://learn.microsoft.com/en-us/windows/apps/design/style/mica>
- Microsoft NavigationView guidance: desktop Windows apps benefit from adaptive top-level navigation that supports left and top navigation styles.
  <https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/navigationview>
- Plex Discover: discovery, universal watchlist, search, ratings, and community signals are part of the viewing decision flow.
  <https://www.plex.tv/discover/>
- Stremio 5 for Windows: Windows media apps can retain familiar design while rebuilding the shell for better performance and desktop behavior.
  <https://blog.stremio.com/stremio-5-released-for-windows/>
- Stremio 2026 updates: player affordances such as media keys, zoom, HDR badges, and subtitle context actions continue to matter in desktop media UX.
  <https://blog.stremio.com/>

## Selected Direction

Chosen direction: **A1 Cinematic Discover**.

The app should first improve its cinematic discovery experience:

- A stronger hero area on the homepage.
- Clearer horizontal discovery sections.
- More purposeful poster cards.
- A cleaner, less noisy detail header.
- A shorter path from detail page to source, episode, and playback.

Search-led and episode-first ideas remain supporting details, but they do not replace the primary cinematic homepage direction in phase one.

## Scope

### In Scope

- `lib/pages/popular/popular_page.dart`
  - Rework the Discover page visual hierarchy.
  - Improve featured content, section headers, tag filters, and poster grids.
  - Keep the existing `PopularController` data flow.

- `lib/bean/card/bangumi_card.dart`
  - Refine poster card styling, badges, text rhythm, image handling, hover/press feedback where available, and desktop/mobile sizing.

- `lib/pages/info/info_page.dart`
  - Rework the detail page header and visual layering.
  - Keep the existing info controller, tabs, and data refresh behavior.

- `lib/bean/card/bangumi_info_card.dart`
  - Improve the cover/title/metadata/rating layout.
  - Preserve skeleton behavior and hero image continuity.

- `lib/pages/info/source_sheet.dart`
  - Make source and episode selection clearer.
  - Improve desktop sheet sizing and mobile bottom-sheet behavior.
  - Add clearer loading, empty, and error states where the existing flow exposes them.

- Small supporting additions in `lib/design`, `lib/bean/widget`, or `lib/bean/card` if they reduce duplication or keep the UI consistent.

### Out of Scope

- No player-engine rewrite.
- No source/rule parser changes.
- No collection sync, download, Danmaku, or WebDAV behavior changes.
- No broad redesign of timeline, collection, search, settings, or plugin pages beyond small navigation affordances needed by the homepage/detail flow.
- No landing page, branding site, or README screenshot replacement in this phase.

## Experience Model

### Desktop

The desktop experience should feel like a Windows media client:

- Navigation remains adaptive, with side navigation on wide layouts and bottom navigation on compact layouts.
- Main pages should use wider content bands instead of simply stretching mobile grids.
- Homepage sections should be scannable from left to right.
- Action buttons should be clear, compact, and close to the object they affect.
- Window controls and app-level commands should stay restrained.

### Mobile

Mobile should keep the existing Material 3 foundation:

- Bottom navigation remains the primary top-level navigation.
- Homepage sections collapse into vertical scroll.
- Detail layout stacks cover art, metadata, and actions.
- Source selection remains a bottom sheet, but with improved hierarchy.

## Homepage Design

The Discover page becomes the flagship surface for this pass.

### Header

The current app bar should become calmer:

- Title: keep `Discover` or the selected tag label.
- Primary commands: search and history.
- Desktop close/window commands remain available but visually secondary.
- Avoid oversized decorative title gradients in compact control areas.

### Hero

The featured area should be more stable and cinematic:

- Use the first high-confidence trending item when the list is available.
- Use poster artwork and a protected gradient text area.
- Show title, score, rank/date where available, and a primary action to open details.
- Keep image loading stable with placeholders and error fallbacks.
- Avoid making text unreadable over bright poster art.

### Sections

Homepage content should be organized into predictable bands:

- `Continue Watching` if existing history data can be read without new backend work. If not feasible in this phase, omit it rather than inventing a fake section.
- `For You` or `Featured` from current trending data.
- `Popular` grid using the existing trend/tag list.
- Tag filter row remains available and easy to scan.

### Poster Cards

Poster cards should support:

- Stable aspect ratio and fixed grid dimensions.
- 8-12px corner radius.
- Low or no heavy shadow on desktop.
- Rating badge when rating exists.
- Rank badge when rank is meaningful.
- Two-line title maximum.
- Secondary metadata only when it improves scanning.

## Detail Page Design

The detail page should keep the successful cinematic backdrop idea but reduce visual noise.

### Header

- Keep the blurred poster background but lower visual intensity.
- Add gradient protection only where text needs it.
- Avoid whole-page blur that makes the page feel washed out.
- Desktop layout: cover art on the left, metadata and actions in the center, rating chart or supporting details on the right when enough width exists.
- Mobile layout: cover art and metadata stack cleanly.

### Metadata

Metadata should be grouped into readable chips or compact rows:

- Air date.
- Score.
- Rank.
- Collection status.
- Rating distribution when enabled and data is complete.

### Main Action

The play/start-watching action should be visually primary:

- It stays available as a floating action or prominent CTA.
- It should not compete with secondary external-link or collection buttons.
- It should open the improved source sheet.

### Tabs

Tabs remain:

- Overview.
- Comments.
- Characters.
- Reviews.
- Staff.

The tab bar should sit on a clear surface and remain readable over the backdrop.

## Source Sheet Design

The source sheet is the bridge from details to playback.

### Structure

Desktop:

- Constrained modal width, closer to a media-client panel than a full-width mobile sheet.
- Top area: source tabs or source selector.
- Main area: episode list.
- Optional status area for current source, loading, or failure.

Mobile:

- Bottom sheet remains.
- Source selector stays near the top.
- Episode list uses a clear grid/list layout with sufficient tap targets.

### States

The sheet must clearly communicate:

- Sources loading.
- No sources available.
- Episode list loading.
- Episode parse failure.
- Selected source.
- Selected episode or current episode.

Playback should not be blocked by non-critical metadata errors.

## Visual Guidelines

- Respect the existing theme provider, dynamic color option, OLED dark mode, and Mi Sans/system-font logic.
- Use poster imagery for cinematic emotion, not large abstract gradients.
- Avoid making the UI a one-note green, purple-blue, beige, or dark-slate palette.
- Keep cards visually calm: moderate radius, low shadow, clear text.
- Do not scale font size with viewport width.
- Text must not overlap poster art, tabs, controls, or neighboring cards.
- Do not add decorative orbs, blobs, or purely atmospheric background elements.
- Use existing Material icons consistently.
- Keep desktop density tighter than mobile without sacrificing hit targets.

## State And Error Handling

- Homepage loading should keep layout stable with a spinner or section placeholder.
- Hero should gracefully fall back when artwork is missing.
- Detail refresh should keep existing image flicker protections.
- Source sheet must show useful error text for empty or failed source/episode states.
- Long anime titles and source names must ellipsize cleanly.
- All redesigned areas must handle light and dark themes.

## Testing And Verification

Required verification before implementation is considered complete:

- Run `flutter analyze --fatal-warnings`.
- Run relevant existing tests when the environment supports them.
- Manually inspect desktop/wide and mobile/narrow layouts.
- Verify Discover page, detail page, and source sheet have no overlapping text or broken controls.
- Verify light and dark theme behavior.
- Verify image-loading failure paths do not collapse layout.

## Acceptance Criteria

Phase one is successful when:

1. The Flutter Discover page has a clearly cinematic hero and organized content sections.
2. Poster cards look consistent across homepage, search-result reuse, and collection reuse where affected.
3. The detail page reads cleanly on both desktop and mobile, with the play CTA easy to find.
4. The source sheet makes source and episode selection clearer than the current version.
5. The changes do not alter source parsing, playback engine behavior, rule logic, or user data.
6. Existing tests and analysis pass, or any environment blocker is documented.
7. Visual inspection confirms no obvious overflow, blank hero, unreadable overlay text, or broken compact layout.

## Risks

- The current app is Flutter/Material 3, so Windows-native Mica and NavigationView cannot be implemented literally in this phase.
- Existing strings in the working tree appear mojibake in the current terminal; implementation should avoid broad text rewrites unless the file encoding is understood.
- Data availability for `Continue Watching` may require careful reuse of history data. If it becomes risky, omit the section for phase one.
- The homepage already has a recent redesign commit, so implementation should avoid churn and improve the existing direction rather than rewriting every widget from scratch.

## Implementation Planning Boundary

The next plan should cover only the first-phase Flutter UI work described here.

Do not plan playback-core changes. Do not plan broad settings/search/timeline/collection redesigns beyond small supporting updates required by the selected homepage, detail page, and source sheet flow.

