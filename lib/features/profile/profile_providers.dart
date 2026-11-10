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

/// 分页加载的列表.
///
/// 加载下一页失败时记录在 [moreError] 中, 列表底部显示 "重试".
class const ListPages<T>({
  required final Paged<T> pages,
  final AppFailure? moreError,
});

typedef DishPages = ListPages<Dish>;

/// 列表的 "加载下一页". 同一时刻只加载一页.
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

/// 我上传的菜. 发布成功后重新请求.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果, 不重新请求.
///
/// 封禁中改用他人主页的接口读取. 受限会话不能调用 `/foods/my`, 但可以调用 `/foods/by-user/{id}`.
@Riverpod(keepAlive: true)
class MyUploads extends _$MyUploads {
  /// 封禁中时为自己的 id, 翻页沿用同一个接口.
  int? _publicOf;

  @override
  Future<DishPages> build() async {
    final me = _myId(ref);
    ref.watch(publishedCountProvider);
    // 本 Provider 常驻, 不能监听会自动销毁的 accountStatusProvider, 因此从登录态计算封禁状态.
    final banned = ref.watch(
      sessionProvider.select(
        (s) => switch (s) {
          SignedIn(:final user, :final restricted) => AccountStatus.of(
            signedIn: true,
            user: user,
            restricted: restricted,
          ) is BannedStatus,
          SignedOut() || Guest() => false,
        },
      ),
    );
    _publicOf = banned ? me : null;
    final foods = ref.watch(foodRepositoryProvider);
    return DishPages(
      pages: await switch (_publicOf) {
        final id? => foods.byUser(id, cancelToken: ref.cancelToken()),
        null => foods.mine(cancelToken: ref.cancelToken()),
      },
    );
  }

  final _more = _MoreLoader<Dish>();

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => switch (_publicOf) {
      final id? => ref.read(foodRepositoryProvider).byUser(id, page: page),
      null => ref.read(foodRepositoryProvider).mine(page: page),
    },
    (next) => state = AsyncData(next),
  );
}

/// 我收藏的菜, 按收藏时间倒序.
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

/// 我收藏的店. 已关门的店排在最后.
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

/// 他人主页的 "上传". 离开页面后保留 5 分钟.
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

/// 粉丝或关注列表.
enum FollowListKind { fans, followings }

/// [userId] 的粉丝或关注列表.
///
/// 对方未公开该列表时失败, [AppFailure.code] 为 `BizCodes.notSupported`, 页面显示 "对方未公开".
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

/// 失败是否因为对方未公开列表.
bool isHiddenList(Object? error) =>
    error is AppFailure && error.code == BizCodes.notSupported;

/// 当前用户是否屏蔽了 [userId]. 他人主页的 "更多" 据此显示 "屏蔽" 或 "解除屏蔽".
@riverpod
class BlockState extends _$BlockState {
  @override
  Future<bool> build(int userId) => ref
      .watch(userRepositoryProvider)
      .isBlocked(userId, cancelToken: ref.cancelToken());

  /// 屏蔽或解除屏蔽. 屏蔽会解除双方的关注关系, 成功后重新请求双方的资料.
  Future<void> set({required bool blocked}) async {
    await ref.read(userRepositoryProvider).setBlocked(userId, blocked: blocked);
    if (!ref.mounted) return;
    state = AsyncData(blocked);
    ref.read(followsProvider.notifier).refresh(userId);
  }
}

/// 我的标签. 只有认证用户能写标签, 未认证时不请求, 返回空列表.
@riverpod
class MyTags extends _$MyTags {
  @override
  Future<List<MyTag>> build() async {
    if (ref.watch(accountStatusProvider) is! VerifiedStatus) return const [];
    return ref
        .watch(foodRepositoryProvider)
        .myTags(cancelToken: ref.cancelToken());
  }

  /// 改名. 失败时抛出 [AppFailure], 列表不变.
  Future<void> rename(MyTag tag, String name) async {
    await ref.read(foodRepositoryProvider).renameMyTag(tag.id, name);
    _replace(tag.id, (t) => MyTag(id: t.id, name: name, usage: t.usage));
  }

  /// 删除标签. 菜不受影响. 失败时抛出 [AppFailure], 列表不变.
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

/// 用我的标签 [tagId] 标过的菜.
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

/// 足迹的一个分栏, 按最近看过排序.
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

  /// 清空本分栏. 失败时抛出 [AppFailure], 列表不变.
  Future<void> clear() async {
    await ref.read(historyRepositoryProvider).clear(kind);
    if (ref.mounted) state = const AsyncData(ListPages(pages: Paged.empty()));
  }
}

/// 本人的等级进度. 每次打开等级页重新请求.
///
/// 等级与 "我的" 舞台上的不一致时 (如今天刚升级), 刷新本人的公开资料.
@riverpod
Future<GrowthProgress> growthProgress(Ref ref) async {
  final progress = await ref
      .watch(growthRepositoryProvider)
      .progress(cancelToken: ref.cancelToken());
  final me = ref.read(sessionProvider);
  if (ref.mounted && me is SignedIn && me.user != null) {
    final shown = ref.read(userProfileProvider(me.user!.id)).value?.level;
    if (shown != null && shown != progress.level) {
      ref.invalidate(userProfileProvider(me.user!.id));
    }
  }
  return progress;
}

/// 本人的经验明细, 按入账时间倒序.
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

/// 换头像时选好的照片和取景. [jpeg] 是按取景裁好的 512×512 头像.
class const AvatarDraft({
  required final PickedPhoto photo,
  required final Uint8List jpeg,
});

/// 保存资料: 更换头像时先上传头像, 然后保存昵称, 签名和头像.
///
/// 成功后刷新当前用户和 "我的" 的资料. 失败时抛出 [AppFailure].
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
