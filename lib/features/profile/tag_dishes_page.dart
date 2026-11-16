import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/profile/widgets/profile_stage.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 展示当前用户使用指定标签标记过的菜品列表, 跨店以两列方块排列.
class TagDishesPage extends ConsumerWidget {
  const new({super.key, required this.tagId, required this.name});

  final int tagId;

  /// 来自路由参数的标签名称, 缺失时页面标题回退为 "我的标签".
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tagDishesProvider(tagId);
    return PlainScaffold(
      title: name.isEmpty ? '我的标签' : name,
      titleNote: '仅自己可见',
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
            message: '在任意菜品下点「加标签」，选「自己写」即可添加。',
          ),
        ),
      ],
    );
  }
}
