import 'dart:async';

import 'package:clock/clock.dart';
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
import 'package:eat/domain/rules/meal_rules.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'publish_providers.g.dart';

/// 输入停下来再查，期间又变了的旧请求不发（技术架构 10.5）。
const _debounce = Duration(milliseconds: 300);

/// 选店列表：离我近的在前，没有定位时按离校区中心的远近（产品 6.9）。[keyword] 为空时是附近的店。
@riverpod
Future<List<Shop>> pickableShops(Ref ref, String keyword) async {
  if (keyword.isNotEmpty) {
    await Future<void>.delayed(_debounce);
    if (!ref.mounted) return const [];
  }
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  final campus = ref.watch(currentPlaceProvider.select((p) => p.campus));
  final near = me ?? campus?.center;
  if (near == null && keyword.isEmpty) return const [];
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        keyword: keyword.isEmpty ? null : keyword,
        near: near,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 「你在万达金街附近」：有定位时我所在的商圈，不在任何商圈里或没有定位时为 null。
@riverpod
Future<Hub?> myHub(Ref ref) async {
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  if (me == null) return null;
  return ref.watch(placeRepositoryProvider).locateHub(me);
}

/// 地图中心所在的商圈，新建店时按位置自动判断（产品 6.9）。
@riverpod
Future<Hub?> hubAt(Ref ref, GcjPoint point) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return null;
  return ref.watch(placeRepositoryProvider).locateHub(point);
}

/// 新建店时附近 200 m 内的同名店（产品 9.2）。
@riverpod
Future<Shop?> sameNameShop(Ref ref, String name, GcjPoint point) async {
  if (name.trim().isEmpty) return null;
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return null;
  return ref
      .watch(placeRepositoryProvider)
      .sameNameNearby(name, point, cancelToken: ref.cancelToken());
}

/// 输完菜名就查重：这家店已有同名的菜时返回那道（产品 6.9）。
@riverpod
Future<Dish?> sameNameDish(Ref ref, int shopId, String name) async {
  if (PublishRules.compactName(name).isEmpty) return null;
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return null;
  return ref
      .watch(foodRepositoryProvider)
      .sameName(shopId, name, cancelToken: ref.cancelToken());
}

/// 一张照片在上传队列里的状态。
enum UploadStatus { waiting, uploading, done, failed }

/// 加菜页上的一张照片：本地的字节、上传进度，传完后拿到的存储 key。
class const DraftPhoto({
  required final int id,
  required final PickedPhoto photo,
  required final ImageProvider image,
  final UploadStatus status = UploadStatus.waiting,
  final double progress = 0,
  final String? key,
  final AppFailure? failure,

  /// 回到前台时自动重试过一次了。
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

/// 加菜页填到一半的内容。照片第一张是封面，裁切和舞台色都是封面的。
class const PublishDraft({
  final List<DraftPhoto> photos = const [],
  final CoverCrop crop = const CoverCrop(),

  /// 封面按 [crop] 取色的结果，算出来之前是 null。
  final StageSuggestion? suggestion,

  /// 用户在「调整照片」里手动选的颜色；选过以后换分类也不再动（产品 6.9）。
  final StageColor? pickedStage,
  final DishCategory? category,
  final Set<MealTime> meals = const {},
  final Set<int> tasteTagIds = const {},
  final List<String> myTags = const [],
}) {
  /// 「调整照片」里的三个推荐色。
  List<StageColor> get candidates =>
      suggestion?.top3(category?.stage ?? StageColor.broth) ?? const [];

  /// 现在用的舞台色。还没照片时用汤色（产品 6.9）。
  StageColor get stage =>
      pickedStage ?? candidates.firstOrNull ?? StageColor.broth;

  /// 存进菜品的两个备选色：推荐色里除了选中的，不够再按远近补；取色还没出结果时按枚举顺序补，
  /// 接口要求正好两个。
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

  /// 所有照片合起来的上传进度，0–1。
  double get uploadProgress => photos.isEmpty
      ? 0
      : photos
                .map((p) => p.status == UploadStatus.done ? 1.0 : p.progress)
                .reduce((a, b) => a + b) /
            photos.length;

  PublishDraft copy({
    List<DraftPhoto>? photos,
    CoverCrop? crop,
    StageSuggestion? suggestion,
    bool clearSuggestion = false,
    StageColor? pickedStage,
    bool clearPicked = false,
    DishCategory? category,
    Set<MealTime>? meals,
    Set<int>? tasteTagIds,
    List<String>? myTags,
  }) => PublishDraft(
    photos: photos ?? this.photos,
    crop: crop ?? this.crop,
    suggestion: clearSuggestion ? null : suggestion ?? this.suggestion,
    pickedStage: clearPicked ? null : pickedStage ?? this.pickedStage,
    category: category ?? this.category,
    meals: meals ?? this.meals,
    tasteTagIds: tasteTagIds ?? this.tasteTagIds,
    myTags: myTags ?? this.myTags,
  );
}

/// 加菜页的草稿和照片上传队列，随页面释放，不存草稿（产品 6.9）。
///
/// 照片加进来就在后台传，同时最多 2 张（技术架构 13.3）；失败的单张重试，回到前台时失败的自动重试一次。
@riverpod
class Draft extends _$Draft {
  static const _parallel = 2;

  final _tokens = <int, CancelToken>{};
  var _nextId = 0;

  /// 封面解码好的取色小图，「调整照片」拖动时直接用它重算。
  Future<StageSample>? _coverSample;
  int? _coverSampleId;

  @override
  PublishDraft build() {
    ref.onDispose(() {
      for (final token in _tokens.values) {
        token.cancel();
      }
    });
    return PublishDraft(meals: {MealRules.at(clock.now())});
  }

  /// 加照片，最多补到 9 张。返回加之前是不是一张都没有：是的话页面接着打开「调整照片」。
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

  /// 把一张照片设为封面：挪到第一张，裁切和颜色重来。
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

  /// 回到前台：iOS 在后台可能挂起了请求，失败的条目自动重试一次（技术架构 13.3）。
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

  /// 封面的取色小图，「调整照片」用。没有封面时为 null。
  Future<StageSample>? coverSample() {
    final cover = state.photos.firstOrNull;
    if (cover == null) return null;
    if (_coverSampleId != cover.id) {
      _coverSampleId = cover.id;
      _coverSample = StagePalette.sample(cover.photo.bytes);
    }
    return _coverSample;
  }

  /// 「调整照片」点了「完成」。[picked] 是用户点过的颜色，没点过为 null。
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

  void setCategory(DishCategory category) =>
      state = state.copy(category: category);

  void toggleMeal(MealTime meal) => state = state.copy(
    meals: state.meals.contains(meal)
        ? ({...state.meals}..remove(meal))
        : {...state.meals, meal},
  );

  void toggleTaste(int id) {
    final ids = {...state.tasteTagIds};
    if (!ids.remove(id) && ids.length < PublishRules.tagsMax) ids.add(id);
    state = state.copy(tasteTagIds: ids);
  }

  void addMyTag(String name) {
    final tag = name.trim();
    if (tag.isEmpty ||
        state.myTags.contains(tag) ||
        state.myTags.length >= PublishRules.tagsMax) {
      return;
    }
    state = state.copy(myTags: [...state.myTags, tag]);
  }

  void removeMyTag(String name) =>
      state = state.copy(myTags: [...state.myTags.where((t) => t != name)]);

  void _resetCover() {
    state = state.copy(
      crop: const CoverCrop(),
      clearSuggestion: true,
      clearPicked: true,
    );
    if (state.photos.isNotEmpty) unawaited(_suggestForCover());
  }

  /// 封面按默认的居中裁切先取一次色：「调整照片」点了取消也有颜色可用。
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
      // 解不开的图在选图时就被拦下了；万一到这里，舞台退回分类色。
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
