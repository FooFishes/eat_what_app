import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:eat/state/published.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_providers.g.dart';

/// 获取菜品详情.
///
/// 拿到最新数据后清除赞和收藏的本地乐观覆盖值; 网络不可达时回退到本地缓存, 若无缓存则抛出失败.
/// 监听发布次数变化以在编辑页保存后触发刷新, 因为编辑页位于独立模块, 通过发布计数联动详情更新.
@riverpod
Future<Dish> dishDetail(Ref ref, int dishId) async {
  ref.cacheFor(const Duration(minutes: 5));
  ref.watch(publishedCountProvider);
  final repo = ref.watch(foodRepositoryProvider);
  try {
    final dish = await repo.detail(dishId, cancelToken: ref.cancelToken());
    ref.read(dishInteractionsProvider.notifier).forget(dishId);
    return dish;
  } on AppFailure catch (e) {
    if (e.kind != FailureKind.network) rethrow;
    final cached = await repo.cachedDetail(dishId);
    if (cached == null) rethrow;
    return cached;
  }
}

/// 菜品的修改记录分页. [moreError] 是加载下一页失败的原因.
class const DishRevisionPages({
  required final Paged<DishRevision> pages,
  final AppFailure? moreError,
});

/// 一道菜的修改记录, 最新的在前.
///
/// 恢复成功后重新请求修改记录和菜品详情.
@riverpod
class DishHistory extends _$DishHistory {
  var _loadingMore = false;

  @override
  Future<DishRevisionPages> build(int dishId) async => DishRevisionPages(
    pages: await ref
        .watch(foodRepositoryProvider)
        .history(dishId, cancelToken: ref.cancelToken()),
  );

  /// 加载下一页. 同一时刻只加载一页.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.pages.hasNext || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(foodRepositoryProvider)
          .history(dishId, page: current.pages.page + 1);
      if (ref.mounted) {
        state = AsyncData(DishRevisionPages(pages: current.pages.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(
          DishRevisionPages(pages: current.pages, moreError: e),
        );
      }
    } finally {
      _loadingMore = false;
    }
  }

  /// 把菜品恢复到 [revision] 之后的内容. 失败时抛出 [AppFailure].
  ///
  /// 成功后通知发布次数变化, 店铺菜单和 "我的" 上传列表随之重新请求.
  Future<void> restore(DishRevision revision) async {
    await ref.read(foodRepositoryProvider).restore(dishId, revision.id);
    ref.read(publishedCountProvider.notifier).published();
    ref.invalidate(dishDetailProvider(dishId));
    ref.invalidateSelf();
  }
}

/// 一道菜的投票口味标签和我的标签.
///
/// 后端 v2 没有口味投票和我的标签接口, 只有保留的加标签面板使用. 菜品详情加载后为空列表.
///
/// 打标签和撤回采用乐观更新: 先修改本地状态, 请求失败时恢复.
class const DishTags({
  required final List<TasteTag> taste,
  required final List<MyTag> mine,
});

@riverpod
class DishTagsOf extends _$DishTagsOf {
  @override
  DishTags? build(int dishId) {
    final dish = ref.watch(dishDetailProvider(dishId)).value;
    if (dish == null) return null;
    return const DishTags(taste: [], mine: []);
  }

  /// 切换 "大家怎么说" 中一个口味词的状态: 未打过则打上, 已打过则撤回.
  ///
  /// 成功返回 null, 失败返回原因.
  Future<AppFailure?> toggleTaste(TasteTag tag) async {
    final before = state;
    if (before == null) return null;
    final mine = before.taste.any((t) => t.id == tag.id && t.mine);
    state = DishTags(
      taste: _withTaste(before.taste, tag, mine: !mine),
      mine: before.mine,
    );
    try {
      final repo = ref.read(foodRepositoryProvider);
      if (mine) {
        await repo.removeTag(dishId, tag.id);
      } else {
        await repo.addTasteTags(dishId, [tag.id]);
      }
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = before;
      return e;
    }
  }

  /// 提交加标签面板的结果.
  ///
  /// - 口味词按选中状态增删.
  /// - [newMine] 中的词加入我的标签.
  ///
  /// 提交后从服务端重新获取标签.
  Future<AppFailure?> apply({
    required Set<int> taste,
    required List<String> newMine,
  }) async {
    final before = state;
    if (before == null) return null;
    final had = {
      for (final t in before.taste)
        if (t.mine) t.id,
    };
    final add = taste.difference(had).toList();
    final remove = had.difference(taste);
    final repo = ref.read(foodRepositoryProvider);
    try {
      if (add.isNotEmpty) await repo.addTasteTags(dishId, add);
      for (final id in remove) {
        await repo.removeTag(dishId, id);
      }
      if (newMine.isNotEmpty) await repo.addMyTags(dishId, newMine);
      final fresh = await repo.tagsOf(dishId);
      if (ref.mounted) state = DishTags(taste: fresh.taste, mine: fresh.mine);
      return null;
    } on AppFailure catch (e) {
      return e;
    }
  }

  static List<TasteTag> _withTaste(
    List<TasteTag> tags,
    TasteTag tag, {
    required bool mine,
  }) {
    final result = <TasteTag>[];
    var found = false;
    for (final t in tags) {
      if (t.id == tag.id) {
        found = true;
        final count = (t.count + (mine ? 1 : -1)).clamp(0, 1 << 31);
        if (count > 0) {
          result.add(
            TasteTag(id: t.id, name: t.name, count: count, mine: mine),
          );
        }
      } else {
        result.add(t);
      }
    }
    if (!found && mine) {
      result.add(TasteTag(id: tag.id, name: tag.name, count: 1, mine: true));
    }
    return result..sort((a, b) => b.count.compareTo(a.count));
  }
}
