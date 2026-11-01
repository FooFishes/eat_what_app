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

/// 我的统计：获赞、上传的菜、粉丝、关注。主页面常驻，切走不重拉（技术架构 10.5）。
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

/// 一页一页往下接的菜品列表，加载下一页失败时记在 [moreError] 里，底部换成「重试」。
class const DishPages({
  required final Paged<Dish> pages,
  final AppFailure? moreError,
});

/// 我上传的菜。
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

/// 我收藏的菜，新收藏的在前。
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
