import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/storage/cache_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_repository.g.dart';

/// 菜品数据. 把接口 DTO 转换为 [Dish], 并缓存浏览过的菜品详情.
///
/// 标签的方法对应的接口在后端 v2 中已删除, 只有保留的待接入页面引用.
class FoodRepository {
  FoodRepository(this._api, this._cache);

  final FoodApi _api;
  final CacheStore _cache;

  static const _detailGroup = 'dish';

  Future<Dish> detail(int id, {CancelToken? cancelToken}) async {
    final dto = await _api.detail(id, cancelToken: cancelToken);
    await _cache.write(
      _detailGroup,
      '$id',
      jsonEncode(dto.toJson()),
      maxEntries: 50,
    );
    return toDish(dto);
  }

  /// 缓存的菜品详情, 用于离线或请求返回前先行显示. 过期的缓存不返回.
  Future<Dish?> cachedDetail(int id) async {
    final raw = await _cache.read(
      _detailGroup,
      '$id',
      maxAge: const Duration(days: 7),
    );
    if (raw == null) return null;
    try {
      return toDish(FoodDto.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } on Object {
      return null;
    }
  }

  /// 按条件查询菜品, 返回的分页带 [Paged.total]. 不按校区过滤.
  ///
  /// - [keyword] 只匹配菜名.
  /// - 不传 [sort] 时, 指定 [restaurantId] 按菜单顺序, 否则按最新排列.
  Future<Paged<Dish>> list({
    int? restaurantId,
    String? keyword,
    DishCategory? category,
    bool? signatureOnly,
    FoodSort? sort,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => _map(
    await _api.list(
      restaurantId: restaurantId,
      keyword: keyword,
      category: category?.api,
      signatureOnly: signatureOnly,
      sort: sort,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  /// 我收藏的菜, 按收藏时间倒序.
  Future<Paged<Dish>> favorites({
    int page = 1,
    CancelToken? cancelToken,
  }) async => _map(await _api.favorites(page: page, cancelToken: cancelToken));

  /// 我首次发布的菜, 最新的在前.
  Future<Paged<Dish>> mine({int page = 1, CancelToken? cancelToken}) async =>
      _map(await _api.mine(page: page, cancelToken: cancelToken));

  /// 发布菜品, 返回新菜品的 id. 发布后即公开, 不经审核.
  ///
  /// 失败时抛出 [AppFailure]:
  /// - 同一店铺已有同名菜品时, 业务码为 `BizCodes.duplicateDish`, `data.id` 是已有菜品的 id.
  /// - 标为招牌菜而店铺已有 3 道招牌菜时, 业务码为 `BizCodes.stateNotAllowed`.
  Future<int> publish(NewDish dish) => _api.create(
    CreateFoodDto(
      restaurantId: dish.shopId,
      name: dish.name,
      category: dish.category.api,
      price: dish.price,
      description: dish.description,
      pictures: dish.imageKeys,
      tags: [for (final taste in dish.tags) taste.api],
      signature: dish.signature,
      stageColor: dish.stage.name,
      stageAlternates: [for (final c in dish.stageAlternates) c.name],
      coverCrop: _cropDto(roundCrop(dish.crop)),
    ),
  );

  // TODO: 菜品响应只有图片地址, 没有存储 key, 编辑时无法提交保留的原图. 后端在响应中提供 key 或允许提交原图地址后补充保留原图的方式.
  /// 编辑菜品, 返回本次修改的记录 id. 内容没有变化时返回 null, 不产生修改记录.
  ///
  /// 失败时的业务码与 [publish] 相同: 改名后与同一店铺的菜品重名, 或招牌菜已满.
  Future<int?> edit(int id, DishChange change) => _api.edit(
    id,
    EditFoodDto(
      name: change.name,
      category: change.category?.api,
      price: change.price,
      description: change.description,
      pictures: change.imageKeys,
      tags: change.tags?.map((taste) => taste.api).toList(),
      signature: change.signature,
      stageColor: change.stage?.name,
      stageAlternates: change.stageAlternates?.map((c) => c.name).toList(),
      coverCrop: switch (change.crop) {
        final crop? => _cropDto(roundCrop(crop)),
        null => null,
      },
    ),
  );

  /// 菜品的修改记录, 最新的在前. 不需要登录.
  Future<Paged<DishRevision>> history(
    int id, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.history(id, page: page, cancelToken: cancelToken);
    return Paged(
      items: [for (final dto in result.items) ?_revision(dto)],
      page: result.page,
      hasNext: result.hasNext,
      total: result.total,
    );
  }

  /// 把菜品恢复到 [revisionId] 之后的内容, 记为一次新的修改.
  ///
  /// 当前内容已经是该版本时抛出业务码为 `BizCodes.stateNotAllowed` 的 [AppFailure].
  Future<void> restore(int id, int revisionId) => _api.restore(id, revisionId);

  /// 识别时最多发送的照片张数. 后端超出时拒绝整个请求.
  static const _suggestPhotosMax = 3;

  /// 按菜名, 说明和照片识别分类和口味. 结果只是建议, 由用户确认后再提交.
  ///
  /// [imageKeys] 是本人上传的存储 key, 只发送前 3 张.
  /// 后端未启用识别或识别失败时抛出业务码为 40001 的 [AppFailure].
  Future<DishSuggestion> suggestTags({
    required String name,
    int? shopId,
    String? description,
    List<String> imageKeys = const [],
    CancelToken? cancelToken,
  }) async {
    final dto = await _api.suggestTags(
      SuggestFoodDto(
        name: name,
        restaurantId: shopId,
        description: description,
        pictures: imageKeys.isEmpty
            ? null
            : imageKeys.take(_suggestPhotosMax).toList(),
      ),
      cancelToken: cancelToken,
    );
    return DishSuggestion(
      category: DishCategory.fromApi(dto.category),
      tags: _tastes(dto.tags),
    );
  }

  static CoverCropDto _cropDto(CoverCrop crop) => CoverCropDto(
    centerX: crop.centerX,
    centerY: crop.centerY,
    diameter: crop.diameter,
  );

  /// 把裁切参数取整到 4 位小数. 原取景圈在照片内时, 取整后的取景圈也在照片内.
  ///
  /// 接口对裁切参数最多接受 4 位小数, 超出时以 10001 拒绝整个请求.
  /// 接口和本层都不知道照片尺寸, 因此只按方向取整, 不做四舍五入:
  /// - 直径向下取整, 取景圈只会变小.
  /// - 圆心向 0.5 取整, 只会远离照片边缘. 0.5 本身是 4 位小数, 圆心不会越过照片中线.
  static CoverCrop roundCrop(CoverCrop crop) => CoverCrop(
    centerX: _toward(crop.centerX, up: crop.centerX < 0.5),
    centerY: _toward(crop.centerY, up: crop.centerY < 0.5),
    diameter: _toward(crop.diameter, up: false),
  );

  /// 把 [value] 向上或向下取到 4 位小数.
  ///
  /// `value * 10000` 有浮点误差, 取整后校正一次, 保证结果不小于 (或不大于) [value].
  static double _toward(double value, {required bool up}) {
    const scale = 10000;
    if (up) {
      var n = (value * scale).ceil();
      if (n / scale < value) n++;
      return n / scale;
    }
    var n = (value * scale).floor();
    if (n / scale > value) n--;
    return n / scale;
  }

  /// 该店中与 [name] 同名 (忽略空白和大小写) 的菜品. 没有时返回 null.
  Future<Dish?> sameName(
    int shopId,
    String name, {
    CancelToken? cancelToken,
  }) async {
    final key = PublishRules.dishNameKey(name);
    if (key.isEmpty) return null;
    final page = await list(
      restaurantId: shopId,
      keyword: key,
      pageSize: 50,
      cancelToken: cancelToken,
    );
    for (final dish in page.items) {
      if (PublishRules.dishNameKey(dish.name) == key) return dish;
    }
    return null;
  }

  Future<void> setLiked(int id, {required bool liked}) =>
      liked ? _api.like(id) : _api.unlike(id);

  Future<void> setFavorite(int id, {required bool favorite}) =>
      favorite ? _api.favorite(id) : _api.unfavorite(id);

  Future<List<TasteTag>> tasteVocabulary({CancelToken? cancelToken}) async => [
    for (final dto in await _api.systemTags(cancelToken: cancelToken))
      if (dto.id != null && dto.name != null)
        TasteTag(id: dto.id!, name: dto.name!),
  ];

  /// 该菜品当前的口味标签和我的标签.
  Future<({List<TasteTag> taste, List<MyTag> mine})> tagsOf(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final dto = await _api.tagsOf(id, cancelToken: cancelToken);
    return (taste: _tasteTags(dto.systemTags), mine: _myTags(dto.myCustomTags));
  }

  Future<void> addTasteTags(int id, List<int> tagIds) =>
      _api.addSystemTags(id, tagIds);

  Future<void> addMyTags(int id, List<String> names) =>
      _api.addCustomTags(id, names);

  Future<void> removeTag(int id, int tagId) => _api.removeTag(id, tagId);

  /// 我写过的全部标签, 按接口顺序. 标签数量少, 一次获取全部, 最多请求 10 页.
  Future<List<MyTag>> myTags({CancelToken? cancelToken}) async {
    final tags = <MyTag>[];
    var page = 1;
    while (true) {
      final result = await _api.myTags(page: page, cancelToken: cancelToken);
      tags.addAll(_myTags(result.items));
      if (!result.hasNext || result.items.isEmpty || page >= 10) break;
      page++;
    }
    return tags;
  }

  Future<void> renameMyTag(int tagId, String name) =>
      _api.renameMyTag(tagId, name);

  Future<void> deleteMyTag(int tagId) => _api.deleteMyTag(tagId);

  /// 用我的标签 [tagId] 标过的菜, 跨店查询.
  Future<Paged<Dish>> taggedWith(
    int tagId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async =>
      _map(await _api.taggedWith(tagId, page: page, cancelToken: cancelToken));

  Future<Paged<Dish>> byUser(
    int userId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async =>
      _map(await _api.byUser(userId, page: page, cancelToken: cancelToken));

  Paged<Dish> _map(Paged<FoodDto> page) => Paged(
    items: page.items.map(toDish).toList(),
    page: page.page,
    hasNext: page.hasNext,
    total: page.total,
  );

  /// 把接口的菜品转换为 [Dish].
  ///
  /// 舞台色, 备选色和取景使用服务端保存的值, 没有时舞台色取分类默认色, 取景居中.
  /// 没有图片时不使用取景, 因为取景只针对封面.
  Dish toDish(FoodDto dto) {
    final category = DishCategory.fromApi(dto.category);
    final stages = StageColor.values.asNameMap();
    final images = [
      for (final url in dto.pictureUrls ?? const <String>[]) ?imageUrl(url),
    ];
    final crop = images.isEmpty ? null : dto.coverCrop;
    return Dish(
      id: dto.id ?? 0,
      name: dto.name?.trim() ?? '',
      shopId: dto.restaurantId ?? 0,
      shopName: _text(dto.restaurantName),
      price: dto.price,
      category: category,
      images: images,
      stage: stages[dto.stageColor] ?? DishRules.defaultStage(category),
      stageAlternates: [
        for (final name in dto.stageAlternates ?? const <String>[])
          ?stages[name],
      ],
      crop: crop == null
          ? const CoverCrop()
          : CoverCrop(
              centerX: crop.centerX ?? 0.5,
              centerY: crop.centerY ?? 0.5,
              diameter: crop.diameter ?? 1,
            ),
      tags: _tastes(dto.tags),
      signature: dto.signature ?? false,
      liked: dto.isLiked ?? false,
      favorite: dto.isFavorite ?? false,
      likes: dto.likeCount ?? 0,
      uploaderId: dto.accountId,
      description: _text(dto.description),
      createdAt: dateFromMillis(dto.createdAt),
    );
  }

  static List<Taste> _tastes(List<String>? values) => [
    for (final value in values ?? const <String>[]) ?Taste.fromApi(value),
  ];

  static DishRevision? _revision(FoodRevisionDto dto) {
    final id = dto.id;
    if (id == null) return null;
    final editor = dto.editor;
    return DishRevision(
      id: id,
      action: RevisionAction.fromApi(dto.action),
      editorId: editor?.id,
      editorName: _text(editor?.displayName),
      editorAvatar: imageUrl(editor?.avatar),
      restoredFrom: dto.restoredFrom,
      fields: [
        for (final change in dto.changes ?? const <FoodFieldChangeDto>[])
          ?DishField.fromApi(change.field),
      ],
      createdAt: dateFromMillis(dto.createdAt),
    );
  }

  static List<TasteTag> _tasteTags(List<FoodTagDto>? tags) => [
    for (final tag in tags ?? const <FoodTagDto>[])
      if (tag.id != null && tag.name != null)
        TasteTag(
          id: tag.id!,
          name: tag.name!,
          count: tag.count ?? 0,
          mine: tag.taggedByMe ?? false,
        ),
  ]..sort((a, b) => b.count.compareTo(a.count));

  static List<MyTag> _myTags(List<FoodTagDto>? tags) => [
    for (final tag in tags ?? const <FoodTagDto>[])
      if (tag.id != null && tag.name != null)
        MyTag(id: tag.id!, name: tag.name!, usage: tag.usageCount),
  ];

  static String? _text(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}

@Riverpod(keepAlive: true)
FoodRepository foodRepository(Ref ref) =>
    FoodRepository(ref.watch(foodApiProvider), ref.watch(cacheStoreProvider));
