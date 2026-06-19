import 'package:kazumi/modules/bangumi/bangumi_item.dart';

enum PopularSortMode {
  hot('热门优先'),
  score('评分优先'),
  rank('排名优先'),
  latest('最新优先');

  const PopularSortMode(this.label);

  final String label;
}

enum PopularYearFilter {
  all('全部年份'),
  year2026('2026'),
  year2025('2025'),
  year2024('2024'),
  older('更早');

  const PopularYearFilter(this.label);

  final String label;
}

enum PopularAirStatusFilter {
  all('全部状态'),
  airing('连载中'),
  finished('已完结'),
  upcoming('未开播');

  const PopularAirStatusFilter(this.label);

  final String label;
}

enum PopularVisibilityFilter {
  all('全部作品'),
  rated('高评分'),
  ranked('有排名'),
  cnTitle('有中文名');

  const PopularVisibilityFilter(this.label);

  final String label;
}

class PopularFilterState {
  const PopularFilterState({
    this.sort = PopularSortMode.hot,
    this.year = PopularYearFilter.all,
    this.status = PopularAirStatusFilter.all,
    this.visibility = PopularVisibilityFilter.all,
  });

  final PopularSortMode sort;
  final PopularYearFilter year;
  final PopularAirStatusFilter status;
  final PopularVisibilityFilter visibility;

  bool get hasActiveFilters =>
      sort != PopularSortMode.hot ||
      year != PopularYearFilter.all ||
      status != PopularAirStatusFilter.all ||
      visibility != PopularVisibilityFilter.all;

  List<String> get activeLabels {
    return [
      if (sort != PopularSortMode.hot) sort.label,
      if (year != PopularYearFilter.all) year.label,
      if (status != PopularAirStatusFilter.all) status.label,
      if (visibility != PopularVisibilityFilter.all) visibility.label,
    ];
  }

  PopularFilterState copyWith({
    PopularSortMode? sort,
    PopularYearFilter? year,
    PopularAirStatusFilter? status,
    PopularVisibilityFilter? visibility,
  }) {
    return PopularFilterState(
      sort: sort ?? this.sort,
      year: year ?? this.year,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PopularFilterState &&
        other.sort == sort &&
        other.year == year &&
        other.status == status &&
        other.visibility == visibility;
  }

  @override
  int get hashCode => Object.hash(sort, year, status, visibility);
}

class PopularBangumiSearchQuery {
  const PopularBangumiSearchQuery({
    this.keyword = '',
    required this.sort,
    required this.tags,
    required this.rank,
    required this.airDate,
  });

  final String keyword;
  final String sort;
  final List<String> tags;
  final List<String> rank;
  final List<String> airDate;
}

PopularBangumiSearchQuery buildPopularBangumiSearchQuery(
  PopularFilterState filter, {
  required String currentTag,
  DateTime? now,
}) {
  final normalizedTag = currentTag.trim();
  final dateRange = _mergeDateRanges(
    _yearDateRange(filter.year),
    _statusDateRange(filter.status, now ?? DateTime.now()),
  );

  return PopularBangumiSearchQuery(
    sort: _bangumiSortFor(filter.sort),
    tags: normalizedTag.isEmpty ? const [] : [normalizedTag],
    rank: _rankRangeFor(filter),
    airDate: dateRange.toBangumiFilter(),
  );
}

String _bangumiSortFor(PopularSortMode sort) {
  return switch (sort) {
    PopularSortMode.hot => 'heat',
    PopularSortMode.score => 'score',
    PopularSortMode.rank => 'rank',
    // Bangumi search does not expose a stable date sort in the existing app.
    // Pull a broad ranked set, then apply the local date sort below.
    PopularSortMode.latest => 'rank',
  };
}

List<String> _rankRangeFor(PopularFilterState filter) {
  final needsRankedResults = filter.sort == PopularSortMode.rank ||
      filter.sort == PopularSortMode.score ||
      filter.visibility == PopularVisibilityFilter.ranked ||
      filter.visibility == PopularVisibilityFilter.rated;
  return needsRankedResults
      ? const ['>0', '<=99999']
      : const ['>=0', '<=99999'];
}

_DateRange? _yearDateRange(PopularYearFilter year) {
  return switch (year) {
    PopularYearFilter.all => null,
    PopularYearFilter.year2026 => _DateRange(
        start: DateTime(2026),
        end: DateTime(2027),
      ),
    PopularYearFilter.year2025 => _DateRange(
        start: DateTime(2025),
        end: DateTime(2026),
      ),
    PopularYearFilter.year2024 => _DateRange(
        start: DateTime(2024),
        end: DateTime(2025),
      ),
    PopularYearFilter.older => _DateRange(end: DateTime(2024)),
  };
}

_DateRange? _statusDateRange(PopularAirStatusFilter status, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return switch (status) {
    PopularAirStatusFilter.all => null,
    PopularAirStatusFilter.upcoming => _DateRange(start: today),
    PopularAirStatusFilter.airing => _DateRange(
        start: today.subtract(const Duration(days: 120)),
        end: today.add(const Duration(days: 1)),
      ),
    PopularAirStatusFilter.finished => _DateRange(
        end: today.subtract(const Duration(days: 120)),
      ),
  };
}

_DateRange _mergeDateRanges(_DateRange? first, _DateRange? second) {
  if (first == null && second == null) return const _DateRange();
  if (first == null) return second!;
  if (second == null) return first;

  final start = switch ((first.start, second.start)) {
    (null, final DateTime value) => value,
    (final DateTime value, null) => value,
    (final DateTime a, final DateTime b) => a.isAfter(b) ? a : b,
    _ => null,
  };
  final end = switch ((first.end, second.end)) {
    (null, final DateTime value) => value,
    (final DateTime value, null) => value,
    (final DateTime a, final DateTime b) => a.isBefore(b) ? a : b,
    _ => null,
  };
  return _DateRange(start: start, end: end);
}

class _DateRange {
  const _DateRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  List<String> toBangumiFilter() {
    return [
      if (start != null) '>=${_formatBangumiDate(start!)}',
      if (end != null) '<${_formatBangumiDate(end!)}',
    ];
  }
}

String _formatBangumiDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
}

double popularPosterGridGap(double contentWidth) {
  if (contentWidth >= 1400) return 28;
  if (contentWidth >= 980) return 22;
  return 16;
}

double popularPosterGridTextHeight(double contentWidth) {
  if (contentWidth < 640) return 54;
  return 58;
}

double popularPosterAspectRatio(double contentWidth) {
  return 0.68;
}

int popularPosterGridColumnCount(double contentWidth) {
  if (contentWidth >= 1560) return 7;
  if (contentWidth >= 1260) return 6;
  if (contentWidth >= 1040) return 5;
  if (contentWidth >= 620) return 4;
  return 3;
}

List<T> popularGridItemsExcludingSpotlight<T>(
  List<T> items, {
  required int spotlightStart,
  required int spotlightSize,
}) {
  if (items.length <= spotlightSize) return items;
  final end = spotlightStart + spotlightSize;
  return [
    for (var i = 0; i < items.length; i++)
      if (i < spotlightStart || i >= end) items[i],
  ];
}

List<T> spotlightWindowFor<T>(
  List<T> items, {
  required int start,
  required int size,
}) {
  if (items.length <= size) return items;
  final safeStart = start.clamp(0, items.length - 1);
  final end = (safeStart + size).clamp(0, items.length);
  return items.sublist(safeStart, end);
}

int nextSpotlightIndex({
  required int currentIndex,
  required int itemCount,
}) {
  if (itemCount <= 1) return 0;
  return (currentIndex + 1) % itemCount;
}

int nextSpotlightPageStart({
  required int currentStart,
  required int itemCount,
  required int windowSize,
}) {
  if (itemCount <= windowSize) return 0;
  final nextStart = currentStart + windowSize;
  return nextStart >= itemCount ? 0 : nextStart;
}

List<BangumiItem> filterPopularBangumiItems(
  List<BangumiItem> items,
  PopularFilterState filter,
) {
  final filtered = items.where((item) {
    return _matchesYear(item, filter.year) &&
        _matchesStatus(item, filter.status) &&
        _matchesVisibility(item, filter.visibility);
  }).toList();

  filtered.sort((a, b) {
    switch (filter.sort) {
      case PopularSortMode.score:
        return _compareScore(a, b);
      case PopularSortMode.rank:
        return _compareRank(a, b);
      case PopularSortMode.latest:
        return _compareDate(a, b);
      case PopularSortMode.hot:
        return 0;
    }
  });

  return filtered;
}

bool _matchesYear(BangumiItem item, PopularYearFilter year) {
  if (year == PopularYearFilter.all) return true;
  final parsedYear = _airDateYear(item.airDate);
  if (parsedYear == null) return false;
  return switch (year) {
    PopularYearFilter.year2026 => parsedYear == 2026,
    PopularYearFilter.year2025 => parsedYear == 2025,
    PopularYearFilter.year2024 => parsedYear == 2024,
    PopularYearFilter.older => parsedYear < 2024,
    PopularYearFilter.all => true,
  };
}

bool _matchesStatus(BangumiItem item, PopularAirStatusFilter status) {
  if (status == PopularAirStatusFilter.all) return true;
  final date = DateTime.tryParse(item.airDate);
  if (date == null) return false;
  final now = DateTime.now();
  return switch (status) {
    PopularAirStatusFilter.upcoming => date.isAfter(now),
    PopularAirStatusFilter.airing => !date.isAfter(now) &&
        date.isAfter(now.subtract(const Duration(days: 120))),
    PopularAirStatusFilter.finished =>
      date.isBefore(now.subtract(const Duration(days: 120))),
    PopularAirStatusFilter.all => true,
  };
}

bool _matchesVisibility(BangumiItem item, PopularVisibilityFilter visibility) {
  return switch (visibility) {
    PopularVisibilityFilter.all => true,
    PopularVisibilityFilter.rated => item.ratingScore >= 8,
    PopularVisibilityFilter.ranked => item.rank > 0,
    PopularVisibilityFilter.cnTitle => item.nameCn.trim().isNotEmpty,
  };
}

int _compareScore(BangumiItem a, BangumiItem b) {
  final scoreCompare = b.ratingScore.compareTo(a.ratingScore);
  if (scoreCompare != 0) return scoreCompare;
  return _compareRank(a, b);
}

int _compareRank(BangumiItem a, BangumiItem b) {
  final aRank = a.rank <= 0 ? 1 << 30 : a.rank;
  final bRank = b.rank <= 0 ? 1 << 30 : b.rank;
  final rankCompare = aRank.compareTo(bRank);
  if (rankCompare != 0) return rankCompare;
  return b.ratingScore.compareTo(a.ratingScore);
}

int _compareDate(BangumiItem a, BangumiItem b) {
  final aDate = DateTime.tryParse(a.airDate);
  final bDate = DateTime.tryParse(b.airDate);
  if (aDate == null && bDate == null) return 0;
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return bDate.compareTo(aDate);
}

int? _airDateYear(String value) {
  final date = DateTime.tryParse(value);
  return date?.year;
}
