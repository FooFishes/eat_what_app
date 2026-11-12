import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/profile/widgets/profile_stage.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 标签下的菜: 我用某个标签标过的菜, 跨店列出, 两列方块.
class TagDishesPage extends ConsumerWidget {
  const new({super.key, required this.tagId, required this.name});

  final int tagId;

  /// 标签名, 来自地址. 缺失时标题为 "我的标签".
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tagDishesProvider(tagId);
    return PlainScaffold(
      title: name.isEmpty ? '我的标签' : name,
      subtitle: '只有你自己看得见',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [provider],
        wait: () => ref.read(provider.future),
      ),
      slivers: [
        DishGridSliver(
          value: ref.watch(provider),
          showShop: true,
          onRetry: () => ref.invalidate(provider),
          onLoadMore: () => ref.read(provider.notifier).loadMore(),
          empty: const EmptyState(
            icon: EatIcons.tag,
            title: '这个标签下还没有菜',
            message: '在菜品详情点「加标签」，用「自己写」加上这个标签。',
          ),
        ),
      ],
    );
  }
}
