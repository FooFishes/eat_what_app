import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/user/user_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/state/published.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

/// 我的统计: 获赞, 上传的菜, 粉丝, 关注.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求. 发布成功后重新请求.
@Riverpod(keepAlive: true)
Future<UserProfile?> myProfile(Ref ref) async {
  final id = ref.watch(
    sessionProvider.select((s) => s is SignedIn ? s.user?.id : null),
  );
  if (id == null) return null;
  ref.watch(publishedCountProvider);
  return ref
      .watch(userRepositoryProvider)
      .profile(id, cancelToken: ref.cancelToken());
}

/// 分页加载的菜品列表.
///
/// 加载下一页失败时记录在 [moreError] 中, 列表底部显示 "重试".
class const DishPages({
  required final Paged<Dish> pages,
  final AppFailure? moreError,
});

/// 我上传的菜. 发布成功后重新请求.
@Riverpod(keepAlive: true)
class MyUploads extends _$MyUploads {
  @override
  Future<DishPages> build() async {
    ref.watch(sessionProvider.select((s) => s is SignedIn ? s.user?.id : null));
    ref.watch(publishedCountProvider);
    return DishPages(
      pages: await ref
          .watch(foodRepositoryProvider)
          .mine(cancelToken: ref.cancelToken()),
    );
  }

  var _loading = false;

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.pages.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await ref
          .read(foodRepositoryProvider)
          .mine(page: current.pages.page + 1);
      if (ref.mounted) {
        state = AsyncData(DishPages(pages: current.pages.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(DishPages(pages: current.pages, moreError: e));
      }
    } finally {
      _loading = false;
    }
  }
}

/// 我收藏的菜, 按收藏时间倒序.
@Riverpod(keepAlive: true)
class MyFavorites extends _$MyFavorites {
  @override
  Future<DishPages> build() async {
    ref.watch(sessionProvider.select((s) => s is SignedIn ? s.user?.id : null));
    return DishPages(
      pages: await ref
          .watch(foodRepositoryProvider)
          .favorites(cancelToken: ref.cancelToken()),
    );
  }

  var _loading = false;

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.pages.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await ref
          .read(foodRepositoryProvider)
          .favorites(page: current.pages.page + 1);
      if (ref.mounted) {
        state = AsyncData(DishPages(pages: current.pages.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(DishPages(pages: current.pages, moreError: e));
      }
    } finally {
      _loading = false;
    }
  }
}
