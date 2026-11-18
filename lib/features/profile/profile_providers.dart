import 'dart:typed_data';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/growth/growth_repository.dart';
import 'package:eat/data/history/history_repository.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/data/user/user_repository.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/growth.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/published.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/social.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

/// 分页加载的列表状态.
///
/// 加载下一页失败时将错误记录在 [moreError] 中, 列表底部据此显示 "重试".
class const ListPages<T>({
  required final Paged<T> pages,
  final AppFailure? moreError,
});

typedef DishPages = ListPages<Dish>;

/// 列表分页加载器, 同一时刻仅允许加载一页.
class _MoreLoader<T> {
  var _loading = false;

  Future<void> load(
    Ref ref,
    ListPages<T>? current,
    Future<Paged<T>> Function(int page) fetch,
    void Function(ListPages<T> next) emit,
  ) async {
    if (current == null || !current.pages.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await fetch(current.pages.page + 1);
      if (ref.mounted) emit(ListPages(pages: current.pages.append(next)));
    } on AppFailure catch (e) {
      if (ref.mounted) emit(ListPages(pages: current.pages, moreError: e));
    } finally {
      _loading = false;
    }
  }
}

int? _myId(Ref ref) =>
    ref.watch(sessionProvider.select((s) => s is SignedIn ? s.user?.id : null));

/// 当前用户上传的菜品列表, 发布成功后会自动刷新.
///
/// "我的" 为常驻主页面, 切换到其他主页面后保留已加载结果而不会重新请求.
/// 账号封禁期间改用他人主页接口读取, 因为受限会话无法调用 `/foods/my`, 但可调用 `/foods/by-user/{id}`.
@Riverpod(keepAlive: true)
class MyUploads extends _$MyUploads {
  @override
  Future<DishPages> build() async {
    _myId(ref);
    ref.watch(publishedCountProvider);
    return DishPages(
      pages: await ref
          .watch(foodRepositoryProvider)
          .mine(cancelToken: ref.cancelToken()),
    );
  }

  final _more = _MoreLoader<Dish>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(foodRepositoryProvider).mine(page: page),
    (next) => state = AsyncData(next),
  );
}

/// 当前用户收藏的菜品列表, 按收藏时间倒序排列.
@Riverpod(keepAlive: true)
class MyFavorites extends _$MyFavorites {
  @override
  Future<DishPages> build() async {
    _myId(ref);
    return DishPages(
      pages: await ref
          .watch(foodRepositoryProvider)
          .favorites(cancelToken: ref.cancelToken()),
    );
  }

  final _more = _MoreLoader<Dish>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(foodRepositoryProvider).favorites(page: page),
    (next) => state = AsyncData(next),
  );
}

/// 当前用户赞过的菜品列表, 按点赞时间倒序排列.
@Riverpod(keepAlive: true)
class MyLikes extends _$MyLikes {
  @override
  Future<DishPages> build() async {
    _myId(ref);
    return DishPages(
      pages: await ref
          .watch(foodRepositoryProvider)
          .likes(cancelToken: ref.cancelToken()),
    );
  }

  final _more = _MoreLoader<Dish>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(foodRepositoryProvider).likes(page: page),
    (next) => state = AsyncData(next),
  );
}

/// 当前用户收藏的店铺列表, 已关门的店铺排在最后.
@Riverpod(keepAlive: true)
class MyFavoriteShops extends _$MyFavoriteShops {
  @override
  Future<ListPages<Shop>> build() async {
    _myId(ref);
    return ListPages(
      pages: await ref
          .watch(placeRepositoryProvider)
          .favoriteShops(cancelToken: ref.cancelToken()),
    );
  }

  final _more = _MoreLoader<Shop>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(placeRepositoryProvider).favoriteShops(page: page),
    (next) => state = AsyncData(next),
  );
}

/// 他人主页的 "上传" 菜品列表, 离开页面后缓存保留 5 分钟.
@riverpod
class UserUploads extends _$UserUploads {
  @override
  Future<DishPages> build(int userId) async {
    ref.cacheFor(const Duration(minutes: 5));
    return DishPages(
      pages: await ref
          .watch(foodRepositoryProvider)
          .byUser(userId, cancelToken: ref.cancelToken()),
    );
  }

  final _more = _MoreLoader<Dish>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(foodRepositoryProvider).byUser(userId, page: page),
    (next) => state = AsyncData(next),
  );
}

/// 粉丝或关注列表类型.
enum FollowListKind { fans, followings }

/// [userId] 的粉丝或关注列表.
///
/// 若对方未公开该列表则请求失败, 此时 [AppFailure.code] 为 `BizCodes.permissionDenied`, 页面据此显示 "对方未公开".
@riverpod
class FollowList extends _$FollowList {
  @override
  Future<ListPages<UserBrief>> build(int userId, FollowListKind kind) async =>
      ListPages(pages: await _fetch(1));

  final _more = _MoreLoader<UserBrief>();

  Future<Paged<UserBrief>> _fetch(int page) {
    final users = ref.read(userRepositoryProvider);
    final token = page == 1 ? ref.cancelToken() : null;
    return switch (kind) {
      FollowListKind.fans => users.followers(
        userId,
        page: page,
        cancelToken: token,
      ),
      FollowListKind.followings => users.followings(
        userId,
        page: page,
        cancelToken: token,
      ),
    };
  }

  Future<void> loadMore() =>
      _more.load(ref, state.value, _fetch, (next) => state = AsyncData(next));
}

/// 判断失败是否由对方未公开列表所致; 粉丝和关注列表接口仅在该场景下返回无权限错误.
bool isHiddenList(Object? error) =>
    error is AppFailure && error.code == BizCodes.permissionDenied;

/// 判断失败是否由用户不存在所致, 以便页面显示 "该用户不存在", 而非复用登录场景的默认提示.
bool isMissingUser(Object? error) =>
    error is AppFailure && error.code == BizCodes.userNotFound;

/// 当前用户是否已屏蔽 [userId], 供他人主页 "更多" 菜单显示 "屏蔽" 或 "解除屏蔽".
///
/// 该状态直接取自对方用户资料, 不单独发起请求.
@riverpod
class BlockState extends _$BlockState {
  @override
  Future<bool> build(int userId) async =>
      (await ref.watch(userProfileProvider(userId).future)).blocked;

  /// 屏蔽或解除屏蔽该用户. 屏蔽操作会解除双方的关注关系, 成功后会重新请求双方资料以同步状态.
  Future<void> set({required bool blocked}) async {
    await ref.read(userRepositoryProvider).setBlocked(userId, blocked: blocked);
    if (!ref.mounted) return;
    state = AsyncData(blocked);
    ref.read(followsProvider.notifier).refresh(userId);
  }
}

/// 当前用户的自定义标签列表. 仅认证用户支持编写标签, 未认证时不发起请求而直接返回空列表.
@riverpod
class MyTags extends _$MyTags {
  @override
  Future<List<MyTag>> build() async {
    if (ref.watch(accountStatusProvider) is! VerifiedStatus) return const [];
    return ref
        .watch(foodRepositoryProvider)
        .myTags(cancelToken: ref.cancelToken());
  }

  /// 重命名指定标签; 若请求失败则抛出 [AppFailure], 列表保持不变.
  Future<void> rename(MyTag tag, String name) async {
    await ref.read(foodRepositoryProvider).renameMyTag(tag.id, name);
    _replace(tag.id, (t) => MyTag(id: t.id, name: name, usage: t.usage));
  }

  /// 删除指定标签, 已关联的菜品不受影响; 若请求失败则抛出 [AppFailure], 列表保持不变.
  Future<void> delete(MyTag tag) async {
    await ref.read(foodRepositoryProvider).deleteMyTag(tag.id);
    _replace(tag.id, (_) => null);
  }

  void _replace(int id, MyTag? Function(MyTag tag) update) {
    final tags = state.value;
    if (!ref.mounted || tags == null) return;
    state = AsyncData([
      for (final tag in tags)
        if (tag.id != id) tag else ?update(tag),
    ]);
  }
}

/// 使用当前用户标签 [tagId] 标记过的菜品列表.
@riverpod
class TagDishes extends _$TagDishes {
  @override
  Future<DishPages> build(int tagId) async => DishPages(
    pages: await ref
        .watch(foodRepositoryProvider)
        .taggedWith(tagId, cancelToken: ref.cancelToken()),
  );

  final _more = _MoreLoader<Dish>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(foodRepositoryProvider).taggedWith(tagId, page: page),
    (next) => state = AsyncData(next),
  );
}

/// 浏览足迹分栏列表, 按最近浏览时间倒序排列.
@riverpod
class Footprints extends _$Footprints {
  @override
  Future<ListPages<Footprint>> build(FootprintKind kind) async => ListPages(
    pages: await ref
        .watch(historyRepositoryProvider)
        .list(kind, cancelToken: ref.cancelToken()),
  );

  final _more = _MoreLoader<Footprint>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(historyRepositoryProvider).list(kind, page: page),
    (next) => state = AsyncData(next),
  );

  /// 清空当前足迹分栏; 若请求失败则抛出 [AppFailure], 列表保持不变.
  Future<void> clear() async {
    await ref.read(historyRepositoryProvider).clear(kind);
    if (ref.mounted) state = const AsyncData(ListPages(pages: Paged.empty()));
  }
}

/// 当前用户的等级进度, 每次进入等级页时重新请求.
@riverpod
Future<GrowthProgress> growthProgress(Ref ref) => ref
    .watch(growthRepositoryProvider)
    .progress(cancelToken: ref.cancelToken());

/// 当前用户的经验值明细列表, 按入账时间倒序排列.
@riverpod
class ExperienceLedger extends _$ExperienceLedger {
  @override
  Future<ListPages<ExperienceEntry>> build() async => ListPages(
    pages: await ref
        .watch(growthRepositoryProvider)
        .ledger(cancelToken: ref.cancelToken()),
  );

  final _more = _MoreLoader<ExperienceEntry>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(growthRepositoryProvider).ledger(page: page),
    (next) => state = AsyncData(next),
  );
}

/// 更换头像时选定的照片及裁切结果, 其中 [jpeg] 为按取景框裁切后的 512×512 头像数据.
class const AvatarDraft({
  required final PickedPhoto photo,
  required final Uint8List jpeg,
});

/// 保存个人资料; 若更换了头像则先上传头像文件, 再提交昵称, 签名和头像信息.
///
/// 保存成功后刷新当前用户及 "我的" 页面资料, 失败时抛出 [AppFailure].
@riverpod
class ProfileSaver extends _$ProfileSaver {
  @override
  bool build() => false;

  Future<void> save({
    required String nickname,
    required String signature,
    AvatarDraft? avatar,
  }) async {
    if (state) return;
    state = true;
    try {
      final key = avatar == null
          ? null
          : await ref
                .read(uploaderProvider)
                .upload(avatar.jpeg, biz: UploadBiz.avatar);
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            nickname: nickname,
            signature: signature,
            avatarKey: key,
          );
      await ref.read(sessionProvider.notifier).refreshUser();
      if (ref.read(sessionProvider) case SignedIn(user: final user?)) {
        ref.invalidate(userProfileProvider(user.id));
      }
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
