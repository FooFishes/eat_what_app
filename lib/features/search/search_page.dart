import 'dart:async';

import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_choice_group.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/morph_popover.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/search/search_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 搜索页, 采用白底布局并在打开时自动弹出输入键盘.
///
/// - 顶部搜索框替代页面标题与返回按钮同行固定, 不随结果列表滚动.
/// - 未输入关键词时展示最近搜索记录, 若无历史记录则显示可搜索范围说明.
/// - 搜索结果分为 "菜" 与 "店" 两个分栏: 默认展示 "菜", 仅店铺存在结果时自动切至 "店".
/// - "菜" 按发布时间倒序排列且不显示距离; "店" 默认按距离升序排列, 已关门店铺不论哪种排序都排至末尾并标注状态.
/// - 再点一次选中的分栏, 从那一栏长出一个小浮层, 放这一栏的筛选: "菜" 按饭点筛, 默认不限;
///   "店" 换排序, 默认离我近. 浮层开着时点另一栏, 浮层跟过去换成那一栏的选项. 选了就生效并收起.
///   两栏的筛选各自保留, 不是默认值时分栏文字旁带小圆点.
/// - 改了筛选后停在当前这一栏, 不再按结果自动切换; 改关键词后重新按结果决定停在哪一栏.
/// - 无匹配结果时展示 "没找到" 空状态, 认证用户额外展示 "新建一家店" 入口.
class SearchPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _input = TextEditingController();
  var _keyword = '';

  /// 记录用户手动切换的分栏索引; 非 null 时停止根据结果数量自动切换分栏.
  int? _tab;

  /// "菜" 栏筛的饭点, null 表示不限.
  MealTime? _meal;

  /// "店" 栏的排序.
  var _order = ShopOrder.distance;

  /// 筛选浮层是否开着; 开着时挂在当前选中的分栏上.
  var _filterOpen = false;

  /// 两个分栏文字的位置, 筛选浮层从这里长出来.
  final _anchors = [GlobalKey(), GlobalKey()];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _search(String value) {
    final keyword = value.trim();
    setState(() {
      _keyword = keyword;
      _tab = null;
      _filterOpen = false;
    });
  }

  void _submit(String value) {
    _search(value);
    unawaited(ref.read(searchHistoryProvider.notifier).add(value));
  }

  /// 在 [tab] 栏的筛选里选了一项: 收起浮层; 和原来不同 ([changed]) 时生效, 并停在这一栏.
  void _applyFilter(int tab, VoidCallback change, {required bool changed}) =>
      setState(() {
        if (changed) {
          change();
          _tab = tab;
        }
        _filterOpen = false;
      });

  void _useHistory(String word) {
    _input.text = word;
    _submit(word);
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _keyword;
    return PlainScaffold(
      title: '搜索',
      // 搜索框与返回按钮在同一行并固定在顶部. 结果滚动到任意位置时都可以修改关键词.
      header: EatSearchField(
        hintText: '搜菜名或店名',
        controller: _input,
        autofocus: true,
        onChanged: _search,
        onSubmitted: _submit,
      ),
      slivers: [
        if (keyword.isEmpty)
          _History(onPick: _useHistory)
        else
          ..._results(keyword),
      ],
    );
  }

  List<Widget> _results(String keyword) {
    final dishes = ref.watch(dishSearchProvider(keyword, _meal));
    final shops = ref.watch(shopSearchProvider(keyword, _order));
    final dishCount = dishes.value?.length;
    final shopCount = shops.value?.length;
    final auto = dishCount == 0 && (shopCount ?? 0) > 0 ? 1 : 0;
    final tab = _tab ?? auto;
    void remember() =>
        unawaited(ref.read(searchHistoryProvider.notifier).add(keyword));
    return [
      SliverToBoxAdapter(
        child: Transform.translate(
          offset: const Offset(0, -4),
          child: MorphPopover(
            anchor: _filterOpen ? [_anchors[tab]] : null,
            gap: EatSpace.s14,
            label: tab == 0 ? '筛选菜' : '店的排序',
            onDismiss: () => setState(() => _filterOpen = false),
            builder: (_) => tab == 0
                ? EatChoiceGroup(
                    title: '吃哪顿',
                    options: const [null, ...MealTime.values],
                    selected: _meal,
                    label: (meal) => meal?.label ?? '不限',
                    onPick: (meal) => _applyFilter(
                      0,
                      () => _meal = meal,
                      changed: meal != _meal,
                    ),
                  )
                : EatChoiceGroup(
                    title: '排序',
                    options: ShopOrder.values,
                    selected: _order,
                    label: (order) => order.label,
                    onPick: (order) => _applyFilter(
                      1,
                      () => _order = order,
                      changed: order != _order,
                    ),
                  ),
            child: EatTabs(
              tabs: [
                EatTabItem('菜', count: dishCount, indicator: _meal?.label),
                EatTabItem(
                  '店',
                  count: shopCount,
                  indicator: _order == ShopOrder.distance ? null : _order.label,
                ),
              ],
              selected: tab,
              onSelected: (i) => setState(() => _tab = i),
              onReselect: (_) => setState(() => _filterOpen = !_filterOpen),
              reselectHint: _filterOpen ? '收起筛选' : '筛选',
              expanded: _filterOpen,
              anchors: _anchors,
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
      if (tab == 0)
        _resultSliver(
          dishes,
          keyword,
          retry: () => ref.invalidate(dishSearchProvider(keyword, _meal)),
          // 搜菜接口未返回店铺位置与商圈信息, 因此菜品卡片仅展示店名.
          builder: (items) => SliverTileGrid(
            count: items.length,
            builder: (context, i) {
              final dish = items[i];
              return DishTile(
                image: networkImage(
                  dish.cover,
                  width: MediaQuery.sizeOf(context).width / 2,
                ),
                name: dish.name,
                price: DishRules.priceText(dish.price),
                shop: dish.shopName,
                onTap: () {
                  remember();
                  context.push(Paths.dish(dish.id), extra: dish);
                },
              );
            },
          ),
        )
      else
        _resultSliver(
          shops,
          keyword,
          retry: () => ref.invalidate(shopSearchProvider(keyword, _order)),
          builder: (items) => SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (context, i) => ShopRow(
              shop: items[i],
              onTap: () {
                remember();
                context.push(Paths.shop(items[i].id));
              },
            ),
          ),
        ),
    ];
  }

  Widget _resultSliver<T>(
    AsyncValue<List<T>> result,
    String keyword, {
    required VoidCallback retry,
    required Widget Function(List<T> items) builder,
  }) {
    final items = result.value;
    if (items == null) {
      if (result.hasError && !result.isLoading) {
        return SliverToBoxAdapter(
          child: FailureState(error: result.error, onRetry: retry),
        );
      }
      return const SliverToBoxAdapter(child: RowListPlaceholder(count: 4));
    }
    if (items.isEmpty) {
      return SliverToBoxAdapter(child: _NotFound(keyword: keyword));
    }
    return builder(items);
  }
}

/// 展示最近搜索关键词并支持一键清空的列表区域.
class _History extends ConsumerWidget {
  const new({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final words = ref.watch(searchHistoryProvider).value ?? const <String>[];
    if (words.isEmpty) {
      return SliverToBoxAdapter(
        child: Text(
          '菜名、店名都能搜。搜过的词会留在这里。',
          style: eat.text.body.copyWith(color: eat.colors.inkMuted),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ListGroupTitle('最近搜过'),
              const Spacer(),
              EatTappable(
                onTap: () => ref.read(searchHistoryProvider.notifier).clear(),
                label: '清空最近搜过的词',
                builder: (context, _) => SizedBox(
                  height: EatSize.touch,
                  child: Center(
                    child: Text(
                      '清空',
                      style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: EatSpace.s8,
            children: [
              for (final word in words)
                EatChip.choice(
                  word,
                  selected: false,
                  onTap: () => onPick(word),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 搜索无结果时的空状态视图.
///
/// 对已认证用户额外提供 "新建一家店" 按钮, 跳转时以当前搜索词作为店名初值, 建店后直接进入加菜页.
class _NotFound extends ConsumerWidget {
  const new({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verified = ref.watch(accountStatusProvider) is VerifiedStatus;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
      child: EmptyState(
        icon: EatIcons.search,
        title: '没找到「$keyword」',
        message: '换个词试试，或者少打几个字。',
        action: verified
            ? EatButton.outline(
                '新建一家店',
                icon: EatIcons.store,
                height: 48,
                onPressed: () async {
                  if (await guardAction(context, ref, Capability.createShop) &&
                      context.mounted) {
                    unawaited(context.push(Paths.publishShop(name: keyword)));
                  }
                },
              )
            : null,
      ),
    );
  }
}
