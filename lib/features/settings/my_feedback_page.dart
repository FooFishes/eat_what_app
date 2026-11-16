import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/fact_list.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/photo_viewer.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/feedback_case.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/report.dart';
import 'package:eat/domain/rules/feedback_case_rules.dart';
import 'package:eat/features/settings/my_feedback_providers.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 我的反馈列表页, 列出本人提交的意见反馈, 店铺信息有误和举报及其处理状态, 点击进入详情.
class MyFeedbackPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final value = ref.watch(myFeedbackCasesProvider);
    final data = value.value;
    final now = clock.now();
    return PlainScaffold(
      title: '我的反馈',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [myFeedbackCasesProvider],
        wait: () => ref.read(myFeedbackCasesProvider.future),
      ),
      slivers: [
        if (data == null)
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    message: (value.error as AppFailure?)?.message,
                    onRetry: () => ref.invalidate(myFeedbackCasesProvider),
                  )
                : const RowListPlaceholder(count: 4, thumbSize: EatSize.avatar),
          )
        else if (data.pages.items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: EatIcons.feedback,
                title: '还没有提交过反馈',
                message: '提交的反馈、信息有误和举报会记录在这里，处理后可以查看结果。',
              ),
            ),
          )
        else ...[
          SliverList.separated(
            itemCount: data.pages.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s16),
            itemBuilder: (context, i) {
              final item = data.pages.items[i];
              final note = item.text;
              return EatListRow(
                leading: _KindIcon(item.kind),
                title: Text(
                  FeedbackCaseRules.title(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                lines: [
                  if (item.kind != CaseKind.feedback && note.isNotEmpty)
                    Text(note, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '${FeedbackCaseRules.statusLabel(item)} · '
                    '${TimeFormat.date(item.createdAt, now)}',
                    style: eat.text.meta.copyWith(
                      color: eat.colors.inkMuted,
                      fontWeight: item.closed ? FontWeight.w600 : null,
                    ),
                  ),
                ],
                onTap: () => context.push(Paths.myFeedbackCase(item.id)),
              );
            },
          ),
          if (data.pages.hasNext)
            SliverToBoxAdapter(
              child: LoadMoreTrigger(
                generation: data.pages.items.length,
                failed: data.moreError != null,
                onVisible: () =>
                    ref.read(myFeedbackCasesProvider.notifier).loadMore(),
              ),
            ),
        ],
      ],
    );
  }
}

/// 列表行左侧表示记录类型的图标, `mist` 圆底.
class _KindIcon extends StatelessWidget {
  const new(this.kind);

  final CaseKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Container(
      width: EatSize.avatar,
      height: EatSize.avatar,
      decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
      child: Center(
        child: EatIcon(
          switch (kind) {
            CaseKind.feedback => EatIcons.feedback,
            CaseKind.catalogError => EatIcons.store,
            CaseKind.report => EatIcons.report,
          },
          size: 20,
          color: c.ink,
        ),
      ),
    );
  }
}

/// 我的反馈中单条记录的详情页, 展示提交的内容, 截图和处理结果; 关联菜或店时可以跳过去查看.
class FeedbackCasePage extends ConsumerWidget {
  const new({super.key, required this.caseId});

  final int caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = feedbackCaseProvider(caseId);
    final value = ref.watch(provider);
    final item = value.value;
    return PlainScaffold(
      title: item == null ? '反馈详情' : FeedbackCaseRules.kindLabel(item.kind),
      titleNote: item == null ? null : FeedbackCaseRules.statusLabel(item),
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [provider],
        wait: () => ref.read(provider.future),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: switch (item) {
            final item? => _CaseDetail(item: item),
            null when value.hasError && !value.isLoading => FailureState(
              message: (value.error as AppFailure?)?.message,
              onRetry: () => ref.invalidate(provider),
            ),
            null => const LoadingArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: EatSpace.s10,
                children: [
                  Skeleton.line(width: 180),
                  Skeleton.line(width: 140),
                  Skeleton.line(width: 220),
                ],
              ),
            ),
          },
        ),
      ],
    );
  }
}

class _CaseDetail extends StatelessWidget {
  const new({required this.item});

  final FeedbackCase item;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final now = clock.now();
    final body = eat.text.body.copyWith(color: c.ink);
    final reason = FeedbackCaseRules.reasonLabel(item);
    final subject = item.subject;
    final noun = FeedbackCaseRules.subjectNoun(subject);
    final closedAt = item.closedAt;
    final open = switch (subject) {
      CaseSubject(kind: CaseSubjectKind.dish, :final id) => (
        '查看这道菜',
        Paths.dish(id),
      ),
      CaseSubject(kind: CaseSubjectKind.shop, :final id) => (
        '查看这家店',
        Paths.shop(id),
      ),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FactList([
          if (noun != null) (label: '对象', value: noun, strong: false),
          if (reason != null) (label: '原因', value: reason, strong: false),
          (
            label: '提交时间',
            value: TimeFormat.date(item.createdAt, now),
            strong: false,
          ),
          if (closedAt != null)
            (
              label: '处理时间',
              value: TimeFormat.date(closedAt, now),
              strong: false,
            ),
        ]),
        if (item.text.isNotEmpty) ...[
          const SizedBox(height: EatSpace.s20),
          ListGroupTitle(item.kind == CaseKind.feedback ? '内容' : '补充说明'),
          const SizedBox(height: EatSpace.s8),
          Text(item.text, style: body),
        ],
        if (item.screenshots.isNotEmpty) ...[
          const SizedBox(height: EatSpace.s20),
          const ListGroupTitle('截图'),
          const SizedBox(height: EatSpace.s8),
          Row(
            spacing: EatSpace.s10,
            children: [
              for (final (i, url) in item.screenshots.indexed)
                EatTappable(
                  label: '查看截图 ${i + 1}',
                  focusShape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(EatRadius.thumbLg),
                  ),
                  onTap: () => Navigator.of(context).push(
                    PhotoViewer.route(
                      photos: [
                        for (final u in item.screenshots) ViewerPhoto(url: u),
                      ],
                      initialIndex: i,
                    ),
                  ),
                  builder: (_, _) => ListThumb(
                    image: networkImage(url, width: EatSize.thumbLg),
                    size: EatSize.thumbLg,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: EatSpace.s20),
        const ListGroupTitle('处理结果'),
        const SizedBox(height: EatSpace.s8),
        Text(FeedbackCaseRules.outcomeSentence(item), style: body),
        if (item.reply.isNotEmpty) ...[
          const SizedBox(height: EatSpace.s20),
          const ListGroupTitle('回复'),
          const SizedBox(height: EatSpace.s8),
          Text(item.reply, style: body),
        ],
        if (open case (final label, final path)) ...[
          const SizedBox(height: 28),
          EatButton.mist(label, onPressed: () => context.push(path)),
        ],
      ],
    );
  }
}
