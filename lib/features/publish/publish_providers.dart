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
import 'package:eat/domain/models/meal_time.dart';
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

/// 获取当前校区内营业中的可选店铺列表; [keyword] 为空时列出附近店铺, 否则按店名或地址搜索.
///
/// - 列表按与用户的距离升序排列; 无定位时按与校区中心的距离排列, 两者均缺失时按创建时间倒序.
/// - 搜店接口包含已关门店铺, 此处统一过滤排除.
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

/// 当前用户所在的商圈, 用于选店页的位置提示; 无定位或不在任何商圈内时返回 null.
@riverpod
Future<Hub?> myHub(Ref ref) async {
  final me = ref.watch(currentLocationProvider.select((s) => s.point));
  if (me == null) return null;
  return ref.watch(placeRepositoryProvider).locateHub(me);
}

/// 获取地图中心坐标所属的商圈, 用于新建店铺时自动确定商圈.
@riverpod
Future<Hub?> hubAt(Ref ref, GcjPoint point) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return null;
  return ref.watch(placeRepositoryProvider).locateHub(point);
}

/// 查询新建店铺时可能重复的已有店铺 (包含已关门店铺), 涵盖地图地点 [poi] 关联店铺及 [point] 200 m 内的同名店铺.
///
/// 仅用于表单内防重提示而非强制拦截, 并在输入防抖后发起查询.
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

/// 检索与 [keyword] 匹配的地图候选地点, 优先在当前位置附近搜索, 无定位时回退至校区中心附近.
///
/// 当 [keyword] 为空时返回空列表, 检索异常时抛出错误状态.
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

/// 对指定店铺内的菜名查重, 若已存在同名菜品则返回该菜品, 否则返回 null.
///
/// 查重接口还会返回菜名相近的菜, 这里只取同名的.
@riverpod
Future<DishDuplicate?> sameNameDish(Ref ref, int shopId, String name) async {
  if (PublishRules.compactName(name).isEmpty) return null;
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return null;
  final found = await ref
      .watch(foodRepositoryProvider)
      .duplicates(shopId, name, cancelToken: ref.cancelToken());
  return found.where((d) => d.sameName).firstOrNull;
}

/// 发布和编辑菜品时可选的分类, 口味, 饭点和数量上限.
///
/// 请求失败时使用内置值, 不打断填写. 每次打开加菜页重新请求.
@riverpod
Future<DishOptions> dishOptions(Ref ref) async {
  try {
    return await ref
        .watch(foodRepositoryProvider)
        .options(cancelToken: ref.cancelToken());
  } on AppFailure {
    return const DishOptions();
  }
}

/// 按 id 读取待编辑菜品详情, 供编辑页未从详情页带入菜品对象时 (如在 Web 端刷新) 使用.
@riverpod
Future<Dish> dishToEdit(Ref ref, int dishId) => ref
    .watch(foodRepositoryProvider)
    .detail(dishId, cancelToken: ref.cancelToken());

/// 照片在上传队列中的状态.
enum UploadStatus { waiting, uploading, done, failed }

/// 加菜页中的单张待上传照片模型, 包含本地图片数据, 上传状态, 进度及上传完成后的存储 key.
class const DraftPhoto({
  required final int id,
  required final PickedPhoto photo,
  required final ImageProvider image,
  final UploadStatus status = UploadStatus.waiting,
  final double progress = 0,
  final String? key,
  final AppFailure? failure,

  /// 应用回到前台时是否已触发过自动重试, 每张照片最多自动重试一次.
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

/// 加菜页的表单草稿状态, 首张照片默认为封面, 裁切与舞台色均绑定于封面.
///
/// 编辑已有菜品时, [photos] 仅保存待替换的新照片; 若为空则表示保留原有照片.
class const PublishDraft({
  final List<DraftPhoto> photos = const [],
  final CoverCrop crop = const CoverCrop(),

  /// 封面按 [crop] 取色的结果. 计算完成前为 null.
  final StageSuggestion? suggestion,

  /// 用户在 "调整照片" 页面手动选定的舞台色.
  ///
  /// 非 null 时优先级高于自动推荐色, 且后续更换分类也不会覆盖该颜色.
  final StageColor? pickedStage,
  final DishCategory? category,

  /// 选中的口味, 最多 [DishOptions.tagsMax] 个.
  final Set<Taste> tastes = const {},
  final bool signature = false,

  /// 这道菜自己的饭点. 为空表示沿用店铺的饭点.
  final Set<MealTime> mealTimes = const {},
  final bool deliveryEnabled = false,

  /// 标记当前分类或口味是否来自自动识别预选且尚未被用户手动修改.
  final bool preselected = false,
}) {
  /// 按枚举顺序排列的口味, 用于提交.
  List<Taste> get tasteList => [
    for (final taste in Taste.values)
      if (tastes.contains(taste)) taste,
  ];

  /// 按枚举顺序排列的饭点, 用于提交.
  List<MealTime> get mealList => [
    for (final meal in MealTime.values)
      if (mealTimes.contains(meal)) meal,
  ];

  /// 供 "调整照片" 使用的推荐舞台色列表; 取色可靠时按色距排序, 不可靠时首位回退为分类默认色.
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

  /// 计算当前草稿相对于 [original] 的修改内容, 若无任何改动则返回 null.
  ///
  /// - [name] 与 [description] 需传入去除首尾空白后的文本, 其中 [description] 为空字符串表示清空描述.
  /// - [price] 为 null 表示价格未修改, 因为接口不支持清空已有价格.
  /// - 仅当更换过照片时才提交整组新照片及其封面舞台色, 备选色与取景参数.
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
    final mealsChanged =
        mealTimes.length != original.mealTimes.toSet().length ||
        !mealTimes.every(original.mealTimes.contains);
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
      mealTimes: mealsChanged ? mealList : null,
      deliveryEnabled: deliveryEnabled != original.deliveryEnabled
          ? deliveryEnabled
          : null,
    );
    final empty =
        change.name == null &&
        change.category == null &&
        change.price == null &&
        change.description == null &&
        change.tags == null &&
        change.signature == null &&
        change.imageKeys == null &&
        change.mealTimes == null &&
        change.deliveryEnabled == null;
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
    Set<MealTime>? mealTimes,
    bool? deliveryEnabled,
    bool? preselected,
  }) => PublishDraft(
    photos: photos ?? this.photos,
    crop: crop ?? this.crop,
    suggestion: clearSuggestion ? null : suggestion ?? this.suggestion,
    pickedStage: clearPicked ? null : pickedStage ?? this.pickedStage,
    category: category ?? this.category,
    tastes: tastes ?? this.tastes,
    signature: signature ?? this.signature,
    mealTimes: mealTimes ?? this.mealTimes,
    deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
    preselected: preselected ?? this.preselected,
  );
}

/// 管理加菜页表单草稿及照片上传队列的控制器, 随页面销毁而释放且不持久化.
///
/// - 编辑模式下传入 [original] 以预填分类, 口味, 招牌菜, 饭点与外卖; 发布新菜时该参数为 null.
/// - 照片和口味的上限取自 [dishOptionsProvider], 由页面保持其存活.
/// - 添加照片后立即按并发上限在后台排队上传, 失败的照片支持单张重试.
/// - 应用从后台恢复至前台时, 对尚未自动重试过的失败照片触发一次自动重试.
@riverpod
class Draft extends _$Draft {
  static const _parallel = 2;

  final _tokens = <int, CancelToken>{};
  var _nextId = 0;

  /// 封面图片解码后的取色缩略图缓存, 供 "调整照片" 拖动时快速重算推荐色.
  Future<StageSample>? _coverSample;
  int? _coverSampleId;

  /// 标记当前草稿是否已请求过标签识别; 因后端按用户按天限制调用次数, 每份草稿最多请求一次.
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
      tastes: original.tags.toSet(),
      signature: original.signature,
      mealTimes: original.mealTimes.toSet(),
      deliveryEnabled: original.deliveryEnabled,
    );
  }

  DishOptions get _options =>
      ref.read(dishOptionsProvider).value ?? const DishOptions();

  /// 向草稿追加照片并丢弃超出张数上限的部分.
  ///
  /// 返回添加前草稿是否为空, 当返回 true 时调用方需紧接着打开 "调整照片" 页面.
  bool addPhotos(List<PickedPhoto> picked) {
    final room = _options.photosMax - state.photos.length;
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

  /// 将指定照片设为封面并移至首位, 同时重置裁切与舞台色.
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

  /// 获取封面的取色缩略图供 "调整照片" 使用; 无封面时返回 null, 且同一封面仅解码一次.
  Future<StageSample>? coverSample() {
    final cover = state.photos.firstOrNull;
    if (cover == null) return null;
    if (_coverSampleId != cover.id) {
      _coverSampleId = cover.id;
      _coverSample = StagePalette.sample(cover.photo.bytes);
    }
    return _coverSample;
  }

  /// 应用 "调整照片" 返回的裁切与取色结果; [picked] 为用户手动选定的舞台色, 未选择时为 null.
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

  /// 切换指定口味的选中状态; 若已达到 [DishOptions.tagsMax] 上限而无法继续选中, 则返回 false.
  bool toggleTaste(Taste taste) {
    final tastes = {...state.tastes};
    if (!tastes.remove(taste)) {
      if (tastes.length >= _options.tagsMax) return false;
      tastes.add(taste);
    }
    _tastesTouched = true;
    state = state.copy(tastes: tastes, preselected: false);
    return true;
  }

  void setSignature(bool signature) => state = state.copy(signature: signature);

  /// 切换饭点. 全部取消表示沿用店铺的饭点.
  void toggleMeal(MealTime meal) {
    final meals = {...state.mealTimes};
    if (!meals.remove(meal)) meals.add(meal);
    state = state.copy(mealTimes: meals);
  }

  void setDelivery(bool enabled) =>
      state = state.copy(deliveryEnabled: enabled);

  /// 撤销更换照片操作, 取消未完成的上传任务并清空所有新照片, 编辑模式下恢复展示原有照片.
  void clearPhotos() {
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
    state = state.copy(photos: const []);
    _resetCover();
  }

  /// 根据菜名, 描述及已上传照片识别菜品分类与口味, 并预选至草稿中.
  ///
  /// 仅当封面已上传, 尚未选择分类且当前草稿未发起过识别时触发请求; 若结果返回前用户已手动修改对应项则不予覆盖.
  /// 识别失败 (包括功能未启用, 无法识别或网络异常) 时静默忽略, 保持由用户手动选择.
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
          : suggestion.tags.take(_options.tagsMax).toSet();
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

  /// 按默认居中裁切区域为封面提取推荐色.
  ///
  /// 预先计算可保证即使用户在 "调整照片" 页面取消操作, 草稿依然拥有可用的舞台色.
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
