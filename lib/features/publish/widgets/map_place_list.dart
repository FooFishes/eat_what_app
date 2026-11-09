import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 新建店的第一步: 按关键词搜地图上的店, 从候选里选一家.
///
/// 搜不到时由 [onManual] 转到手动添加.
class MapPlaceList extends ConsumerWidget {
  const new({
    super.key,
    required this.search,
    required this.onChanged,
    required this.onSelected,
    required this.onManual,
  });

  final TextEditingController search;
  final ValueChanged<String> onChanged;
  final ValueChanged<MapPlace> onSelected;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final keyword = search.text.trim();
    final places = ref.watch(mapPlacesProvider(keyword));
    Widget note(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: EatSpace.s16),
      child: Text(
        text,
        style: eat.text.body.copyWith(color: eat.colors.inkMuted),
      ),
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: EatSearchField(
            hintText: '搜店名',
            controller: search,
            autofocus: keyword.isEmpty,
            onChanged: onChanged,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        if (keyword.isEmpty)
          SliverToBoxAdapter(child: note('输入店名，从地图上的店里选'))
        else
          switch (places) {
            AsyncData(:final value) when value.isEmpty => SliverToBoxAdapter(
              child: note('附近没搜到「$keyword」'),
            ),
            AsyncData(:final value) => SliverList.separated(
              itemCount: value.length,
              separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s16),
              itemBuilder: (context, i) =>
                  _PlaceRow(place: value[i], onTap: () => onSelected(value[i])),
            ),
            AsyncError() => SliverToBoxAdapter(
              child: FailureState(
                message: '搜索失败',
                onRetry: () => ref.invalidate(mapPlacesProvider(keyword)),
              ),
            ),
            _ => const SliverToBoxAdapter(child: _Placeholder()),
          },
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: EatSpace.s16),
            child: EatButton.add('搜不到？手动添加', onPressed: onManual),
          ),
        ),
      ],
    );
  }
}

class _PlaceRow extends ConsumerWidget {
  const new({required this.place, required this.onTap});

  final MapPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = ref.watch(distanceToProvider(place.point));
    final address = place.address.isEmpty ? null : place.address;
    final where = [?distance, ?address].join('  ');
    return EatListRow(
      title: Text(place.name),
      lines: [if (where.isNotEmpty) Text(where)],
      onTap: onTap,
    );
  }
}

/// 检索中的占位: 几行店名和地址的灰条. 候选没有缩略图.
class _Placeholder extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => LoadingArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 18,
      children: [
        for (var i = 0; i < 4; i++)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EatSpace.s8,
            children: [
              Skeleton.line(width: 160, fontSize: 16),
              Skeleton.line(width: 220, fontSize: 13),
            ],
          ),
      ],
    ),
  );
}
