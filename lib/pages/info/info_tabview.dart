import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/character_card.dart';
import 'package:kazumi/bean/card/staff_card.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/characters/character_item.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/modules/staff/staff_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InfoTabView extends StatefulWidget {
  const InfoTabView({
    super.key,
    required this.episodesIsLoading,
    required this.episodesQueryTimeout,
    required this.episodesIsEmpty,
    required this.episodesLoaded,
    required this.selectedEpisodeRoad,
    required this.roadList,
    required this.charactersQueryTimeout,
    required this.charactersIsEmpty,
    required this.staffQueryTimeout,
    required this.staffIsEmpty,
    required this.tabController,
    required this.loadEpisodes,
    required this.openSourceSheet,
    required this.selectEpisodeRoad,
    required this.playEpisode,
    required this.loadCharacters,
    required this.loadStaff,
    required this.bangumiItem,
    required this.characterList,
    required this.staffList,
    required this.isLoading,
  });

  final bool episodesIsLoading;
  final bool episodesQueryTimeout;
  final bool episodesIsEmpty;
  final bool episodesLoaded;
  final int selectedEpisodeRoad;
  final List<Road> roadList;
  final bool charactersQueryTimeout;
  final bool charactersIsEmpty;
  final bool staffQueryTimeout;
  final bool staffIsEmpty;
  final TabController tabController;
  final Future<void> Function() loadEpisodes;
  final VoidCallback openSourceSheet;
  final ValueChanged<int> selectEpisodeRoad;
  final void Function({required int road, required int episode}) playEpisode;
  final Future<void> Function() loadCharacters;
  final Future<void> Function() loadStaff;
  final BangumiItem bangumiItem;
  final List<CharacterItem> characterList;
  final List<StaffFullItem> staffList;
  final bool isLoading;

  @override
  State<InfoTabView> createState() => _InfoTabViewState();
}

class _InfoTabViewState extends State<InfoTabView> {
  static const double maxWidth = 1180.0;

  Widget get episodeListBody {
    if (widget.episodesIsLoading) {
      return const _EpisodeStatePanel(
        icon: Icons.sync_rounded,
        title: '正在加载选集',
        message: '正在读取上一次使用的播放源和集数列表',
        showProgress: true,
      );
    }

    if (widget.episodesQueryTimeout) {
      return GeneralErrorWidget(
        errMsg: '选集加载失败，请重新选择播放源',
        actions: [
          GeneralErrorButton(
            onPressed: widget.loadEpisodes,
            text: '重试',
          ),
          GeneralErrorButton(
            onPressed: widget.openSourceSheet,
            text: '选择播放源',
          ),
        ],
      );
    }

    if (!widget.episodesLoaded ||
        widget.episodesIsEmpty ||
        widget.roadList.isEmpty) {
      return _EpisodeStatePanel(
        icon: Icons.playlist_play_rounded,
        title: '选择播放源后显示选集',
        message: '第一次打开这部作品时，需要先从规则聚合搜索里选择一个可用播放源。',
        actionLabel: '搜索播放源',
        onAction: widget.openSourceSheet,
      );
    }

    final selectedRoad =
        widget.selectedEpisodeRoad.clamp(0, widget.roadList.length - 1).toInt();
    final road = widget.roadList[selectedRoad];
    final episodeCount = math.min(road.data.length, road.identifier.length);

    if (episodeCount == 0) {
      return _EpisodeStatePanel(
        icon: Icons.playlist_remove_rounded,
        title: '当前播放源没有可用选集',
        message: '换一个播放源试试，或者回到详情页重新搜索规则结果。',
        actionLabel: '重新选择播放源',
        onAction: widget.openSourceSheet,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: CustomScrollView(
          key: const PageStorageKey<String>('episodes'),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: _EpisodeRoadSelector(
                  roadList: widget.roadList,
                  selectedRoad: selectedRoad,
                  onSelected: widget.selectEpisodeRoad,
                  onChangeSource: widget.openSourceSheet,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width >= 980
                      ? 6
                      : width >= 720
                          ? 5
                          : width >= 520
                              ? 4
                              : 3;
                  return SliverGrid.builder(
                    itemCount: episodeCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.35,
                    ),
                    itemBuilder: (context, index) {
                      return _EpisodeTile(
                        label: road.identifier[index],
                        episode: index + 1,
                        onTap: () => widget.playEpisode(
                          road: selectedRoad,
                          episode: index + 1,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get staffListBody {
    if (widget.staffQueryTimeout) {
      return GeneralErrorWidget(
        errMsg: '获取失败，请重试',
        actions: [
          GeneralErrorButton(
            onPressed: widget.loadStaff,
            text: '重试',
          ),
        ],
      );
    }
    if (widget.staffIsEmpty) {
      return const Center(child: Text('什么都没有找到 (;´д`)'));
    }

    final itemCount = widget.staffList.isNotEmpty ? widget.staffList.length : 8;

    return ListView.builder(
      key: const PageStorageKey<String>('staff'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width > maxWidth
                  ? maxWidth
                  : MediaQuery.sizeOf(context).width - 32,
              child: widget.staffList.isNotEmpty
                  ? StaffCard(staffFullItem: widget.staffList[index])
                  : Skeletonizer.zone(
                      child: ListTile(
                        leading: Bone.circle(size: 36),
                        title: Bone.text(width: 100),
                        subtitle: Bone.text(width: 80),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget get charactersListBody {
    if (widget.charactersQueryTimeout) {
      return GeneralErrorWidget(
        errMsg: '获取失败，请重试',
        actions: [
          GeneralErrorButton(
            onPressed: widget.loadCharacters,
            text: '重试',
          ),
        ],
      );
    }
    if (widget.charactersIsEmpty) {
      return const Center(child: Text('什么都没有找到 (;´д`)'));
    }

    final itemCount =
        widget.characterList.isNotEmpty ? widget.characterList.length : 4;

    return ListView.builder(
      key: const PageStorageKey<String>('characters'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width > maxWidth
                  ? maxWidth
                  : MediaQuery.sizeOf(context).width - 32,
              child: widget.characterList.isNotEmpty
                  ? CharacterCard(characterItem: widget.characterList[index])
                  : Skeletonizer.zone(
                      child: ListTile(
                        leading: Bone.circle(size: 36),
                        title: Bone.text(width: 100),
                        subtitle: Bone.text(width: 80),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tabController,
      builder: (context, _) {
        return IndexedStack(
          index: widget.tabController.index,
          sizing: StackFit.expand,
          children: [
            episodeListBody,
            charactersListBody,
            staffListBody,
          ],
        );
      },
    );
  }
}

class _EpisodeRoadSelector extends StatelessWidget {
  const _EpisodeRoadSelector({
    required this.roadList,
    required this.selectedRoad,
    required this.onSelected,
    required this.onChangeSource,
  });

  final List<Road> roadList;
  final int selectedRoad;
  final ValueChanged<int> onSelected;
  final VoidCallback onChangeSource;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int index = 0; index < roadList.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == roadList.length - 1 ? 0 : 8,
                        ),
                        child: ChoiceChip(
                          selected: selectedRoad == index,
                          label: Text(
                            roadList[index].name.isEmpty
                                ? '线路 ${index + 1}'
                                : roadList[index].name,
                          ),
                          onSelected: (_) => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: onChangeSource,
              icon: const Icon(Icons.manage_search_rounded),
              label: const Text('换源'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.label,
    required this.episode,
    required this.onTap,
  });

  final String label;
  final int episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayLabel = label.trim().isEmpty ? '第 $episode 集' : label.trim();

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.52),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeStatePanel extends StatelessWidget {
  const _EpisodeStatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.62),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: scheme.primary, size: 34),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.42,
                    ),
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.travel_explore_rounded),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
