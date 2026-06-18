import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/bean/card/comments_card.dart';
import 'package:kazumi/bean/card/character_card.dart';
import 'package:kazumi/bean/card/staff_card.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/comments/comment_item.dart';
import 'package:kazumi/modules/characters/character_item.dart';
import 'package:kazumi/modules/staff/staff_item.dart';

class InfoTabView extends StatefulWidget {
  const InfoTabView({
    super.key,
    required this.commentsQueryTimeout,
    required this.commentsIsEmpty,
    required this.charactersQueryTimeout,
    required this.charactersIsEmpty,
    required this.staffQueryTimeout,
    required this.staffIsEmpty,
    required this.tabController,
    required this.loadMoreComments,
    required this.loadCharacters,
    required this.loadStaff,
    required this.bangumiItem,
    required this.commentsList,
    required this.characterList,
    required this.staffList,
    required this.isLoading,
  });

  final bool commentsQueryTimeout;
  final bool commentsIsEmpty;
  final bool charactersQueryTimeout;
  final bool charactersIsEmpty;
  final bool staffQueryTimeout;
  final bool staffIsEmpty;
  final TabController tabController;
  final Future<void> Function({int offset}) loadMoreComments;
  final Future<void> Function() loadCharacters;
  final Future<void> Function() loadStaff;
  final BangumiItem bangumiItem;
  final List<CommentItem> commentsList;
  final List<CharacterItem> characterList;
  final List<StaffFullItem> staffList;
  final bool isLoading;

  @override
  State<InfoTabView> createState() => _InfoTabViewState();
}

class _InfoTabViewState extends State<InfoTabView>
    with SingleTickerProviderStateMixin {
  final maxWidth = 1180.0;

  Widget get commentsListBody {
    if (widget.commentsQueryTimeout) {
      return GeneralErrorWidget(
        errMsg: '获取失败，请重试',
        actions: [
          GeneralErrorButton(
            onPressed: () {
              widget.loadMoreComments(offset: widget.commentsList.length);
            },
            text: '重试',
          ),
        ],
      );
    }
    if (widget.commentsIsEmpty) {
      return const Center(child: Text('什么都没有找到 (´;ω;`)'));
    }

    final itemCount =
        widget.commentsList.isNotEmpty ? widget.commentsList.length : 4;

    return NotificationListener<ScrollEndNotification>(
      onNotification: (scrollEnd) {
        final metrics = scrollEnd.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - 200) {
          widget.loadMoreComments(offset: widget.commentsList.length);
        }
        return true;
      },
      child: ListView.separated(
        key: const PageStorageKey<String>('吐槽'),
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width > maxWidth
                      ? maxWidth
                      : MediaQuery.sizeOf(context).width - 32,
                  child: widget.commentsList.isNotEmpty
                      ? CommentsCard(commentItem: widget.commentsList[index])
                      : CommentsCard.bone(),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width > maxWidth
                      ? maxWidth
                      : MediaQuery.sizeOf(context).width - 32,
                  child: const Divider(
                    thickness: 0.5,
                    indent: 10,
                    endIndent: 10,
                  ),
                ),
              ),
            ),
          );
        },
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
      return const Center(child: Text('什么都没有找到 (´;ω;`)'));
    }

    final itemCount = widget.staffList.isNotEmpty ? widget.staffList.length : 8;

    return ListView.builder(
      key: const PageStorageKey<String>('制作人员'),
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
      return const Center(child: Text('什么都没有找到 (´;ω;`)'));
    }

    final itemCount =
        widget.characterList.isNotEmpty ? widget.characterList.length : 4;

    return ListView.builder(
      key: const PageStorageKey<String>('角色'),
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
            commentsListBody,
            charactersListBody,
            staffListBody,
          ],
        );
      },
    );
  }
}

class _InfoUnderConstructionPanel extends StatelessWidget {
  const _InfoUnderConstructionPanel({required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width > maxWidth
              ? maxWidth
              : MediaQuery.sizeOf(context).width - 32,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.62),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    color: scheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '评论区',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '这一栏还在施工中，吐槽内容请先切到「吐槽」查看。',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoOverviewCard extends StatelessWidget {
  const _InfoOverviewCard({
    required this.bangumiItem,
    required this.fullIntro,
    required this.fullTag,
    required this.onToggleIntro,
    required this.onToggleTag,
  });

  final BangumiItem bangumiItem;
  final bool fullIntro;
  final bool fullTag;
  final VoidCallback onToggleIntro;
  final VoidCallback onToggleTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            final synopsis = _InfoSynopsisSection(
              bangumiItem: bangumiItem,
              fullIntro: fullIntro,
              onToggleIntro: onToggleIntro,
            );
            final facts = _InfoFactsSection(bangumiItem: bangumiItem);
            final tags = _InfoTagsSection(
              bangumiItem: bangumiItem,
              fullTag: fullTag,
              onToggleTag: onToggleTag,
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  synopsis,
                  const SizedBox(height: 22),
                  _InfoColumnDivider(horizontal: true),
                  const SizedBox(height: 20),
                  facts,
                  const SizedBox(height: 22),
                  _InfoColumnDivider(horizontal: true),
                  const SizedBox(height: 20),
                  tags,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: synopsis),
                  const SizedBox(width: 22),
                  const _InfoColumnDivider(),
                  const SizedBox(width: 22),
                  Expanded(flex: 3, child: facts),
                  const SizedBox(width: 22),
                  const _InfoColumnDivider(),
                  const SizedBox(width: 22),
                  Expanded(flex: 4, child: tags),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoSynopsisSection extends StatelessWidget {
  const _InfoSynopsisSection({
    required this.bangumiItem,
    required this.fullIntro,
    required this.onToggleIntro,
  });

  final BangumiItem bangumiItem;
  final bool fullIntro;
  final VoidCallback onToggleIntro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = bangumiItem.summary.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoSectionTitle(
          icon: Icons.notes_rounded,
          title: '媒体简介',
        ),
        const SizedBox(height: 14),
        if (summary.isEmpty)
          Text(
            '暂无简介',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final textStyle = TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.86),
                fontSize: 14,
                height: 1.62,
                fontWeight: FontWeight.w500,
              );
              final span = TextSpan(text: summary, style: textStyle);
              final tp = TextPainter(
                text: span,
                textDirection: TextDirection.ltr,
                maxLines: 7,
              )..layout(maxWidth: constraints.maxWidth);
              final shouldCollapse = tp.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    summary,
                    maxLines: fullIntro ? null : 7,
                    scrollBehavior: const ScrollBehavior().copyWith(
                      scrollbars: false,
                    ),
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                    selectionHeightStyle: ui.BoxHeightStyle.max,
                    style: textStyle,
                  ),
                  if (shouldCollapse) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onToggleIntro,
                      icon: Icon(
                        fullIntro
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                      label: Text(fullIntro ? '收起简介' : '展开简介'),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _InfoFactsSection extends StatelessWidget {
  const _InfoFactsSection({required this.bangumiItem});

  final BangumiItem bangumiItem;

  @override
  Widget build(BuildContext context) {
    final rows = <({IconData icon, String label, String value})>[
      if (bangumiItem.airDate.isNotEmpty)
        (
          icon: Icons.event_rounded,
          label: '首播日期',
          value: bangumiItem.airDate,
        ),
      if (bangumiItem.ratingScore > 0)
        (
          icon: Icons.star_rounded,
          label: 'Bangumi 评分',
          value: bangumiItem.ratingScore.toStringAsFixed(1),
        ),
      if (bangumiItem.rank > 0)
        (
          icon: Icons.leaderboard_rounded,
          label: '综合排名',
          value: '#${bangumiItem.rank}',
        ),
      if (bangumiItem.votes > 0)
        (
          icon: Icons.how_to_vote_rounded,
          label: '评分人数',
          value: '${bangumiItem.votes}',
        ),
      if (bangumiItem.alias.isNotEmpty)
        (
          icon: Icons.badge_rounded,
          label: '别名',
          value: bangumiItem.alias.take(2).join(' / '),
        ),
      if (bangumiItem.info.trim().isNotEmpty)
        (
          icon: Icons.info_outline_rounded,
          label: '资料',
          value: bangumiItem.info.trim(),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoSectionTitle(
          icon: Icons.dashboard_customize_rounded,
          title: '基础信息',
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Text(
            '暂无更多资料',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InfoFactRow(
                icon: row.icon,
                label: row.label,
                value: row.value,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoFactRow extends StatelessWidget {
  const _InfoFactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13,
                      height: 1.34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTagsSection extends StatelessWidget {
  const _InfoTagsSection({
    required this.bangumiItem,
    required this.fullTag,
    required this.onToggleTag,
  });

  final BangumiItem bangumiItem;
  final bool fullTag;
  final VoidCallback onToggleTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tags = bangumiItem.tags;
    final visibleCount = fullTag || tags.length < 13 ? tags.length : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoSectionTitle(
          icon: Icons.sell_rounded,
          title: '主题标签',
        ),
        const SizedBox(height: 14),
        if (tags.isEmpty)
          Text(
            '暂无标签',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: Utils.isDesktop() ? 8 : 6,
            children: [
              for (final tag in tags.take(visibleCount))
                ActionChip(
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.42),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tag.name),
                      if (tag.count > 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          '${tag.count}',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onPressed: () {
                    Modular.to.pushNamed('/search/${tag.name}');
                  },
                ),
              if (tags.length > 12)
                ActionChip(
                  side: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.42),
                  ),
                  backgroundColor: scheme.primaryContainer.withValues(
                    alpha: 0.48,
                  ),
                  avatar: Icon(
                    fullTag
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.add_rounded,
                    color: scheme.primary,
                  ),
                  label: Text(
                    fullTag ? '收起标签' : '更多标签',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: onToggleTag,
                ),
            ],
          ),
      ],
    );
  }
}

class _InfoSectionTitle extends StatelessWidget {
  const _InfoSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.64),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 17, color: scheme.primary),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoColumnDivider extends StatelessWidget {
  const _InfoColumnDivider({this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context)
        .colorScheme
        .outlineVariant
        .withValues(alpha: 0.68);

    if (horizontal) {
      return Divider(height: 1, thickness: 1, color: color);
    }
    return VerticalDivider(width: 1, thickness: 1, color: color);
  }
}
