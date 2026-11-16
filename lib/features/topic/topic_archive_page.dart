import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/topic.dart';
import 'package:eat/domain/rules/topic_rules.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/features/topic/topic_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 往期专题列表页, 按时间倒序展示当前校区已结束的专题.
///
/// 每行展示专题名称, 起止时间及前三道菜品的圆形缩略图, 点击进入对应专题页.
class TopicArchivePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(topicArchiveProvider);
    final campus = ref.watch(currentPlaceProvider.select((p) => p.campus));
    final data = value.value;
    return PlainScaffold(
      title: '往期专题',
      titleNote: campus?.name,
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [topicArchiveProvider],
        wait: () => ref.read(topicArchiveProvider.future),
      ),
      slivers: [
        if (data == null)
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    message: (value.error as AppFailure?)?.message,
                    onRetry: () => ref.invalidate(topicArchiveProvider),
                  )
                : const RowListPlaceholder(count: 5, thumbSize: EatSize.avatar),
          )
        else if (data.pages.items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: EatIcons.topic,
                title: '还没有往期专题',
                message: '当期专题结束后会归档在这里。',
              ),
            ),
          )
        else ...[
          SliverList.separated(
            itemCount: data.pages.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s20),
            itemBuilder: (_, i) => _ArchiveRow(topic: data.pages.items[i]),
          ),
          if (data.pages.hasNext)
            SliverToBoxAdapter(
              child: LoadMoreTrigger(
                generation: data.pages.items.length,
                failed: data.moreFailed,
                onVisible: () =>
                    ref.read(topicArchiveProvider.notifier).loadMore(),
              ),
            ),
        ],
      ],
    );
  }
}

// TODO: 往期专题接口不返回菜的图片, 每一行单独请求专题详情来显示前三道菜. 接口返回封面后改用列表数据.
class _ArchiveRow extends ConsumerWidget {
  const new({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final dishes = ref.watch(topicDetailProvider(topic.id)).value?.dishes;
    return EatListRow(
      title: Text('「${topic.name}」'),
      lines: [Text(TopicRules.range(topic, clock.now()))],
      trailing: dishes == null || dishes.isEmpty
          ? null
          : ExcludeSemantics(
              child: SizedBox(
                height: EatSize.avatar,
                width: EatSize.avatar + (dishes.take(3).length - 1) * 34,
                child: Stack(
                  children: [
                    for (final (i, dish) in dishes.take(3).indexed)
                      Positioned(
                        left: i * 34.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: eat.colors.paper,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: SizedBox.square(
                              dimension: EatSize.avatar - 4,
                              child: CoverImage(
                                image: networkImage(
                                  dish.cover,
                                  width: EatSize.avatar,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      onTap: () => context.push(Paths.topic(topic.id)),
    );
  }
}
