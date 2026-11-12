import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/account_status.dart';
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

/// 搜索页. 白底页面, 打开时自动弹出键盘.
///
/// - 搜索框代替标题, 与返回按钮在同一行, 不随结果滚动.
/// - 未输入时显示最近搜索的词. 没有搜索记录时说明可以搜索的内容.
/// - 结果分为 "菜" 和 "店" 两个分栏. 默认显示 "菜", 只有店有结果时显示 "店".
/// - "菜" 按发布时间倒序, 不写距离. "店" 按距离升序, 已关门的店排在最后并标明.
/// - 没有结果时显示 "没找到". 认证用户额外显示 "新建一家店".
class SearchPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _input = TextEditingController();
  var _keyword = '';

  /// 用户手动选择的分栏. 有值时不再根据结果自动切换分栏.
  int? _tab;

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
    });
  }

  void _submit(String value) {
    _search(value);
    unawaited(ref.read(searchHistoryProvider.notifier).add(value));
  }

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
    final dishes = ref.watch(dishSearchProvider(keyword));
    final shops = ref.watch(shopSearchProvider(keyword));
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
          child: EatTabs(
            tabs: [
              EatTabItem('菜', count: dishCount),
              EatTabItem('店', count: shopCount),
            ],
            selected: tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
      if (tab == 0)
        _resultSliver(
          dishes,
          keyword,
          retry: () => ref.invalidate(dishSearchProvider(keyword)),
          // 搜菜接口不返回店的位置和商圈, 方块只写店名.
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
          retry: () => ref.invalidate(shopSearchProvider(keyword)),
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
          child: FailureState(
            message: (result.error as AppFailure?)?.message,
            onRetry: retry,
          ),
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

/// 最近搜索的词, 可以清空.
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

/// 没有结果时的空状态.
///
/// 认证用户额外显示 "新建一家店". 新建店页面以搜索词作为店名初值, 创建后直接进入加菜页.
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
