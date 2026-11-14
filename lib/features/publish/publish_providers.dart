import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/design/stage/stage_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'publish_providers.g.dart';

/// 输入防抖时长.
///
/// 防抖期间参数变化时, 旧的 Provider 已被释放. 等待结束后检查 `ref.mounted`, 已释放的不再发请求.
const _debounce = Duration(milliseconds: 300);

/// 选店列表: 当前校区内营业中的店. [keyword] 为空时列出附近的店, 否则按店名或地址搜索.
///
/// - 按与用户的距离升序排列. 没有定位时按与校区中心的距离排列, 两者都没有时按新建时间倒序.
/// - 搜店接口也返回已关门的店, 这里去掉.
@riverpod
Future<List<Shop>> pickableShops(Ref ref, String keyword) async {
  // 定位或校区变化时重新请求. 搜店范围由 shopSearchScope 读取.
  ref.watch(currentLocationProvider.select((s) => s.point));
  ref.watch(currentPlaceProvider.select((p) => p.campus));
  if (keyword.isNotEmpty) {
    await Future<void>.delayed(_debounce);
    if (!ref.mounted) return const [];
  }
  final scope = await shopSearchScope(ref);
  if (!ref.mounted || scope == null) return const [];
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        keyword: keyword.isEmpty ? null : keyword,
        campusId: scope.campusId,
        near: scope.point,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return [
    for (final shop in page.items)
      if (!shop.closed) shop,
  ];
}

/// 我当前所在的商圈, 用于选店页的位置提示. 没有定位或不在任何商圈内时为 null.
@riverpod
Future<Hub?> myHub(Ref ref) async {
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  if (me == null) return null;
  return ref.watch(placeRepositoryProvider).locateHub(me);
}

/// 地图中心所在的商圈. 新建店时据此自动确定所属商圈.
@riverpod
Future<Hub?> hubAt(Ref ref, GcjPoint point) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return null;
  return ref.watch(placeRepositoryProvider).locateHub(point);
}

/// 新建店时可能重复的店: 地图地点 [poi] 上已有的店, 或 [point] 200 m 内与 [name] 同名的店, 包括已关门的店.
///
/// 只用于提示, 用户可以继续新建. 输入停顿后再查.
@riverpod
Future<List<ShopDuplicate>> shopDuplicates(
  Ref ref,
  String name,
  GcjPoint point,
  String? poi,
) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  return ref
      .watch(placeRepositoryProvider)
      .duplicates(name, point, poi: poi, cancelToken: ref.cancelToken());
}

/// 新建店的候选: 地图上和 [keyword] 匹配的地点, 在当前位置附近找, 没有定位时在校区中心附近找.
///
/// [keyword] 为空时为空列表. 检索失败时为错误状态.
@riverpod
Future<List<MapPlace>> mapPlaces(Ref ref, String keyword) async {
  if (keyword.isEmpty) return const [];
  ref.watch(currentLocationProvider.select((s) => s.point));
  ref.watch(currentPlaceProvider.select((p) => p.campus));
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final scope = await shopSearchScope(ref);
  if (!ref.mounted || scope?.point == null) return const [];
  return ref.watch(placeRepositoryProvider).mapPlaces(keyword, scope!.point!);
}

/// 菜名查重. 这家店已有同名菜时返回该菜, 否则为 null.
@riverpod
Future<Dish?> sameNameDish(Ref ref, int shopId, String name) async {
  if (PublishRules.compactName(name).isEmpty) return null;
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return null;
  return ref
      .watch(foodRepositoryProvider)
      .sameName(shopId, name, cancelToken: ref.cancelToken());
}

/// 要编辑的菜. 编辑页没有从详情页带入菜品时 (如在 Web 上刷新) 使用.
@riverpod
Future<Dish> dishToEdit(Ref ref, int dishId) => ref
    .watch(foodRepositoryProvider)
    .detail(dishId, cancelToken: ref.cancelToken());

/// 照片在上传队列中的状态.
enum UploadStatus { waiting, uploading, done, failed }

/// 加菜页中的一张照片: 本地字节, 上传进度, 上传完成后获得的存储 key.
class const DraftPhoto({
  required final int id,
  required final PickedPhoto photo,
  required final ImageProvider image,
  final UploadStatus status = UploadStatus.waiting,
  final double progress = 0,
  final String? key,
  final AppFailure? failure,

  /// 回到前台时是否已经自动重试过. 自动重试每张照片只进行一次.
  final bool autoRetried = false,
}) {
  DraftPhoto copy({
    UploadStatus? status,
    double? progress,
    String? key,
    AppFailure? failure,
    bool? autoRetried,
  }) => DraftPhoto(
    id: id,
    photo: photo,
    image: image,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    key: key ?? this.key,
    failure: status == UploadStatus.failed ? failure : null,
    autoRetried: autoRetried ?? this.autoRetried,
  );
}

/// 加菜页的草稿. 第一张照片是封面, 裁切和舞台色都属于封面.
///
/// 编辑已有的菜时, [photos] 只包含换上的新照片. 为空表示不换照片, 页面显示原有照片.
class const PublishDraft({
  final List<DraftPhoto> photos = const [],
  final CoverCrop crop = const CoverCrop(),

  /// 封面按 [crop] 取色的结果. 计算完成前为 null.
  final StageSuggestion? suggestion,

  /// 用户在 "调整照片" 中手动选择的颜色.
  ///
  /// 有值时优先于推荐色, 之后更换分类也不改变舞台色.
  final StageColor? pickedStage,
  final DishCategory? category,

  /// 选中的口味, 最多 [PublishRules.tagsMax] 个.
  final Set<Taste> tastes = const {},
  final bool signature = false,

  /// 分类或口味是按识别结果预选的, 用户之后还没有手动改过.
  final bool preselected = false,
}) {
  /// 按枚举顺序排列的口味, 用于提交.
  List<Taste> get tasteList => [
    for (final taste in Taste.values)
      if (tastes.contains(taste)) taste,
  ];

  /// "调整照片" 中的推荐色. 取色可靠时按距离排序, 不可靠时第一个是分类默认色.
  List<StageColor> get candidates =>
      suggestion?.top3(category?.stage ?? StageColor.broth) ?? const [];

  /// 当前使用的舞台色. 未手动选择且没有取色结果时为 [StageColor.broth].
  StageColor get stage =>
      pickedStage ?? candidates.firstOrNull ?? StageColor.broth;

  /// 随菜品保存的两个备选色. 接口要求恰好两个.
  ///
  /// 依次从以下来源选取, 排除当前舞台色并去重:
  /// 1. 推荐色.
  /// 2. 按距离排序的全部舞台色.
  /// 3. 取色尚无结果时, 按枚举顺序的舞台色.
  List<StageColor> get alternates => [
    ...candidates,
    ...?suggestion?.ranked,
    ...StageColor.values,
  ].where((c) => c != stage).toSet().take(2).toList();

  bool get uploading => photos.any(
    (p) =>
        p.status == UploadStatus.waiting || p.status == UploadStatus.uploading,
  );

  bool get hasFailedUpload =>
      photos.any((p) => p.status == UploadStatus.failed);

  /// 全部照片的平均上传进度, 范围 0–1.
  double get uploadProgress => photos.isEmpty
      ? 0
      : photos
                .map((p) => p.status == UploadStatus.done ? 1.0 : p.progress)
                .reduce((a, b) => a + b) /
            photos.length;

  /// 编辑时相对 [original] 的改动. 没有任何改动时返回 null.
  ///
  /// - [name] 和 [description] 是输入框中去掉首尾空白的文字. [description] 为空表示清除.
  /// - [price] 为 null 表示价格没有改动. 接口不能清除价格.
  /// - 换了照片时提交整组新照片, 以及新封面的舞台色, 备选色和取景. 没换照片时这几项都不提交.
  DishChange? changeFrom(
    Dish original, {
    required String name,
    required double? price,
    required String description,
  }) {
    final tags = tasteList;
    final tagsChanged =
        tags.length != original.tags.toSet().length ||
        !tags.every(original.tags.contains);
    final replacing = photos.isNotEmpty;
    final change = DishChange(
      name: name != original.name ? name : null,
      category: category != original.category ? category : null,
      price: price != null && price != original.price ? price : null,
      description: description != (original.description ?? '')
          ? description
          : null,
      tags: tagsChanged ? tags : null,
      signature: signature != original.signature ? signature : null,
      imageKeys: replacing ? [for (final p in photos) ?p.key] : null,
      stage: replacing ? stage : null,
      stageAlternates: replacing ? alternates : null,
      crop: replacing ? crop : null,
    );
    final empty =
        change.name == null &&
        change.category == null &&
        change.price == null &&
        change.description == null &&
        change.tags == null &&
        change.signature == null &&
        change.imageKeys == null;
    return empty ? null : change;
  }

  PublishDraft copy({
    List<DraftPhoto>? photos,
    CoverCrop? crop,
    StageSuggestion? suggestion,
    bool clearSuggestion = false,
    StageColor? pickedStage,
    bool clearPicked = false,
    DishCategory? category,
    Set<Taste>? tastes,
    bool? signature,
    bool? preselected,
  }) => PublishDraft(
    photos: photos ?? this.photos,
    crop: crop ?? this.crop,
    suggestion: clearSuggestion ? null : suggestion ?? this.suggestion,
    pickedStage: clearPicked ? null : pickedStage ?? this.pickedStage,
    category: category ?? this.category,
    tastes: tastes ?? this.tastes,
    signature: signature ?? this.signature,
    preselected: preselected ?? this.preselected,
  );
}

/// 加菜页的草稿和照片上传队列. 随页面释放, 草稿不持久化.
///
/// - [original] 是正在编辑的菜, 发布新菜时为 null. 编辑时分类, 口味和招牌菜预填为现有的值.
/// - 照片添加后立即在后台上传, 并发数有上限.
/// - 上传失败的照片可以单张重试.
/// - 回到前台时, 失败的照片自动重试一次.
@riverpod
class Draft extends _$Draft {
  static const _parallel = 2;

  final _tokens = <int, CancelToken>{};
  var _nextId = 0;

  /// 封面解码后的取色缩小图. "调整照片" 拖动时用它重算推荐色.
  Future<StageSample>? _coverSample;
  int? _coverSampleId;

  /// 是否已经请求过识别. 每份草稿最多请求一次, 后端对识别按人按天限次.
  var _suggestAsked = false;

  /// 用户是否手动选过分类和口味. 手动选过的项不被识别结果覆盖.
  var _categoryTouched = false;
  var _tastesTouched = false;

  @override
  PublishDraft build({Dish? original}) {
    ref.onDispose(() {
      for (final token in _tokens.values) {
        token.cancel();
      }
    });
    if (original == null) return const PublishDraft();
    return PublishDraft(
      category: original.category,
      tastes: original.tags.take(PublishRules.tagsMax).toSet(),
      signature: original.signature,
    );
  }

  /// 添加照片, 超出张数上限的部分丢弃.
  ///
  /// 返回添加前草稿是否没有照片. 返回 true 时页面接着打开 "调整照片".
  bool addPhotos(List<PickedPhoto> picked) {
    final room = PublishRules.photosMax - state.photos.length;
    if (room <= 0 || picked.isEmpty) return false;
    final first = state.photos.isEmpty;
    state = state.copy(
      photos: [
        ...state.photos,
        for (final photo in picked.take(room))
          DraftPhoto(
            id: _nextId++,
            photo: photo,
            image: ResizeImage(MemoryImage(photo.bytes), width: 1080),
          ),
      ],
    );
    if (first) unawaited(_suggestForCover());
    _pump();
    return first;
  }

  void remove(int id) {
    _tokens.remove(id)?.cancel();
    final wasCover = state.photos.firstOrNull?.id == id;
    state = state.copy(photos: [...state.photos.where((p) => p.id != id)]);
    if (wasCover) _resetCover();
    _pump();
  }

  /// 把一张照片设为封面. 该照片移到第一张, 裁切和舞台色重置.
  void makeCover(int id) {
    final photo = state.photos.where((p) => p.id == id).firstOrNull;
    if (photo == null || state.photos.first.id == id) return;
    state = state.copy(
      photos: [photo, ...state.photos.where((p) => p.id != id)],
    );
    _resetCover();
  }

  void retry(int id) {
    _update(id, (p) => p.copy(status: UploadStatus.waiting, progress: 0));
    _pump();
  }

  // TODO: "后台上传" 的范围未经产品确认, 目前按不保证后台继续上传处理. 确认后按结论调整重试策略.
  /// 回到前台时, 每张失败的照片自动重试一次.
  ///
  /// iOS 可能在 App 进入后台后挂起请求, 导致上传失败.
  void retryFailedOnce() {
    for (final photo in state.photos) {
      if (photo.status == UploadStatus.failed && !photo.autoRetried) {
        _update(
          photo.id,
          (p) => p.copy(
            status: UploadStatus.waiting,
            progress: 0,
            autoRetried: true,
          ),
        );
      }
    }
    _pump();
  }

  /// 封面的取色缩小图, 供 "调整照片" 使用. 没有封面时为 null. 同一封面只解码一次.
  Future<StageSample>? coverSample() {
    final cover = state.photos.firstOrNull;
    if (cover == null) return null;
    if (_coverSampleId != cover.id) {
      _coverSampleId = cover.id;
      _coverSample = StagePalette.sample(cover.photo.bytes);
    }
    return _coverSample;
  }

  /// 应用 "调整照片" 的结果. [picked] 是用户手动选择的颜色, 未选择时为 null.
  void applyCrop(
    CoverCrop crop,
    StageSuggestion suggestion, {
    StageColor? picked,
  }) => state = state.copy(
    crop: crop,
    suggestion: suggestion,
    pickedStage: picked,
    clearPicked: picked == null,
  );

  void setCategory(DishCategory category) {
    _categoryTouched = true;
    state = state.copy(category: category, preselected: false);
  }

  /// 选中或取消一个口味. 已选满 [PublishRules.tagsMax] 个时不能再选, 返回 false.
  bool toggleTaste(Taste taste) {
    final tastes = {...state.tastes};
    if (!tastes.remove(taste)) {
      if (tastes.length >= PublishRules.tagsMax) return false;
      tastes.add(taste);
    }
    _tastesTouched = true;
    state = state.copy(tastes: tastes, preselected: false);
    return true;
  }

  void setSignature(bool signature) => state = state.copy(signature: signature);

  /// 撤销换照片: 删除全部新照片, 取消未完成的上传. 编辑时回到原有照片.
  void clearPhotos() {
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
    state = state.copy(photos: const []);
    _resetCover();
  }

  /// 按菜名, 说明和已上传的照片识别分类和口味, 预选到草稿中.
  ///
  /// 只在封面已上传, 还没选分类且本草稿没有请求过时请求. 结果返回前用户手动选过的项不覆盖.
  /// 识别失败 (未启用, 识别不出或网络错误) 时不提示, 用户照常手动选择.
  Future<void> suggest({
    required String name,
    required int shopId,
    String? description,
  }) async {
    final keys = [for (final p in state.photos) ?p.key];
    if (_suggestAsked ||
        state.photos.firstOrNull?.key == null ||
        state.category != null ||
        _categoryTouched) {
      return;
    }
    _suggestAsked = true;
    try {
      final suggestion = await ref
          .read(foodRepositoryProvider)
          .suggestTags(
            name: name,
            shopId: shopId,
            description: description,
            imageKeys: keys,
          );
      if (!ref.mounted) return;
      final category = _categoryTouched || state.category != null
          ? null
          : suggestion.category;
      final tastes = _tastesTouched || suggestion.tags.isEmpty
          ? null
          : suggestion.tags.take(PublishRules.tagsMax).toSet();
      if (category == null && tastes == null) return;
      state = state.copy(category: category, tastes: tastes, preselected: true);
    } on AppFailure {
      // 识别只是辅助. 失败时保持用户已有的选择, 不打断填写.
    }
  }

  void _resetCover() {
    state = state.copy(
      crop: const CoverCrop(),
      clearSuggestion: true,
      clearPicked: true,
    );
    if (state.photos.isNotEmpty) unawaited(_suggestForCover());
  }

  /// 按默认的居中裁切为封面取色.
  ///
  /// 用户在 "调整照片" 中取消时, 草稿仍有可用的舞台色.
  Future<void> _suggestForCover() async {
    final coverId = state.photos.firstOrNull?.id;
    final sample = coverSample();
    if (sample == null) return;
    try {
      final suggestion = (await sample).suggest();
      if (!ref.mounted || state.photos.firstOrNull?.id != coverId) return;
      if (state.suggestion == null) {
        state = state.copy(suggestion: suggestion);
      }
    } on Object {
      // 无法解码的图片在选图时已被拦截. 此处取色失败时保持无推荐色.
      // TODO: 取色失败时舞台色为 `broth`, 没有按分类默认色回落. 改为取色失败时使用 `category.stage`.
    }
  }

  void _update(int id, DraftPhoto Function(DraftPhoto) change) {
    state = state.copy(
      photos: [for (final p in state.photos) p.id == id ? change(p) : p],
    );
  }

  void _pump() {
    var free =
        _parallel -
        state.photos.where((p) => p.status == UploadStatus.uploading).length;
    for (final photo in state.photos) {
      if (free <= 0) break;
      if (photo.status != UploadStatus.waiting) continue;
      free--;
      unawaited(_upload(photo));
    }
  }

  Future<void> _upload(DraftPhoto photo) async {
    final token = CancelToken();
    _tokens[photo.id] = token;
    _update(photo.id, (p) => p.copy(status: UploadStatus.uploading));
    try {
      final key = await ref
          .read(uploaderProvider)
          .upload(
            photo.photo.bytes,
            biz: UploadBiz.foods,
            cancelToken: token,
            onProgress: (value) {
              if (ref.mounted) {
                _update(photo.id, (p) => p.copy(progress: value));
              }
            },
          );
      if (!ref.mounted) return;
      _update(
        photo.id,
        (p) => p.copy(status: UploadStatus.done, progress: 1, key: key),
      );
    } on AppFailure catch (e) {
      if (!ref.mounted || e.kind == FailureKind.cancelled) return;
      _update(photo.id, (p) => p.copy(status: UploadStatus.failed, failure: e));
    } finally {
      if (identical(_tokens[photo.id], token)) _tokens.remove(photo.id);
      if (ref.mounted) _pump();
    }
  }
}
