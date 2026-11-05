import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:eat/features/publish/widgets/bottom_bar.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 发布流程第 1 步: 选店.
///
/// - 列表按与我的距离升序排列.
/// - 可以按店名搜索. 找不到时可以新建店铺.
///
/// [changing] 为 true 表示由加菜页的 "换一家" 打开. 此时选好后带着店返回加菜页, 不进入下一步.
class PublishPage extends ConsumerStatefulWidget {
  const new({super.key, this.changing = false});

  final bool changing;

  @override
  ConsumerState<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends ConsumerState<PublishPage> {
  final _search = TextEditingController();
  var _keyword = '';
  Shop? _selected;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(currentLocationProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final shop = _selected;
    if (shop == null) return;
    if (widget.changing) {
      context.pop(shop);
    } else {
      await context.push(Paths.publishDish(shop.id));
    }
  }

  Future<void> _newShop() async {
    final name = _keyword.trim();
    if (widget.changing) {
      final shop = await context.push<Shop>(
        Paths.publishShop(name: name, returnShop: true),
      );
      if (shop != null && mounted) context.pop(shop);
    } else {
      await context.push(Paths.publishShop(name: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final shops = ref.watch(pickableShopsProvider(_keyword.trim()));
    final hub = ref.watch(myHubProvider).value;
    final located =
        ref.watch(currentLocationProvider.select((s) => s.point)) != null;
    final selected = _selected;
    return Column(
      children: [
        Expanded(
          child: PlainScaffold(
            title: '在哪家吃的？',
            subtitle: !located
                ? null
                : hub == null
                ? '离你近的排在前面'
                : '你在${hub.name}附近，离你近的排在前面',
            actions: [if (!widget.changing) const _Step()],
            slivers: [
              SliverToBoxAdapter(
                child: EatSearchField(
                  hintText: '搜店名',
                  controller: _search,
                  onChanged: (value) => setState(() => _keyword = value),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
              switch (shops) {
                AsyncData(:final value) when value.isEmpty =>
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: EatSpace.s16,
                      ),
                      child: Text(
                        _keyword.trim().isEmpty
                            ? '这附近还没有店，可以新建一家。'
                            : '没找到「${_keyword.trim()}」',
                        style: eat.text.body.copyWith(
                          color: eat.colors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                AsyncData(:final value) => SliverList.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, i) => _ShopOption(
                    shop: value[i],
                    selected: value[i].id == selected?.id,
                    onSelected: () => setState(() => _selected = value[i]),
                  ),
                ),
                AsyncError(:final error) => SliverToBoxAdapter(
                  child: FailureState(
                    message: (error as AppFailure?)?.message,
                    onRetry: () =>
                        ref.invalidate(pickableShopsProvider(_keyword.trim())),
                  ),
                ),
                _ => const SliverToBoxAdapter(
                  child: RowListPlaceholder(count: 5, thumbSize: EatSize.thumb),
                ),
              },
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: EatSpace.s16),
                  child: EatButton.add('没找到？新建一家店', onPressed: _newShop),
                ),
              ),
            ],
          ),
        ),
        PublishBottomBar(
          child: EatButton.solid(
            selected == null
                ? '先选一家店'
                : widget.changing
                ? '就选${selected.name}'
                : '下一步：给${selected.name}加菜',
            onPressed: selected == null ? null : _next,
          ),
        ),
      ],
    );
  }
}

/// 顶栏右侧的步骤进度.
class _Step extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Semantics(
      label: '第 1 步，共 2 步',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(right: EatSpace.s8),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '1',
                style: eat.text.priceInline.copyWith(color: eat.colors.ink),
              ),
              TextSpan(
                text: ' / 2',
                style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 可选的店铺行: 门头照片, 店名, 距离和商圈, 地址.
class _ShopOption extends ConsumerWidget {
  const new({
    required this.shop,
    required this.selected,
    required this.onSelected,
  });

  final Shop shop;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = ref.watch(distanceToProvider(shop.point));
    final hub = ref.watch(hubNameProvider(shop.hubId));
    final where = [?distance, ?hub, ?shop.address].join('  ');
    return EatRadioRow(
      title: shop.name,
      subtitle: where.isEmpty ? null : Text(where),
      thumbnail: ListThumb(
        image: networkImage(shop.photos.firstOrNull, width: EatSize.thumb),
      ),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
