import 'package:dio/dio.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/topic/topic_api.dart';
import 'package:eat/data/topic/topic_dto.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/topic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topic_repository.g.dart';

/// 专题数据仓库, 负责将接口 DTO 转换为领域模型 [Topic] 和 [TopicDetail].
///
/// 缺少 `id` 或起止时间的专题无法正常展示与跳转, 因此在转换时直接丢弃.
class TopicRepository {
  TopicRepository(this._api);

  final TopicApi _api;

  Future<Topic?> current(int campusId, {CancelToken? cancelToken}) async {
    final dto = await _api.current(campusId, cancelToken: cancelToken);
    return dto == null ? null : _topic(dto);
  }

  Future<Paged<Topic>> history(
    int campusId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.history(
      campusId,
      page: page,
      cancelToken: cancelToken,
    );
    return Paged(
      items: [for (final dto in result.items) ?_topic(dto)],
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  /// 获取专题详情; 若接口返回的专题摘要缺少必要字段, 则按专题不存在处理并返回 null.
  Future<TopicDetail?> detail(int id, {CancelToken? cancelToken}) async {
    final dto = await _api.detail(id, cancelToken: cancelToken);
    final topic = dto.topic == null ? null : _topic(dto.topic!);
    if (topic == null) return null;
    final foods = [...?dto.foods]
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    return TopicDetail(
      topic: topic,
      dishes: [
        for (final food in foods)
          if (food.id != null) _dish(food),
      ],
    );
  }

  /// 获取收录过指定菜品的专题列表, 按开始时间倒序排列.
  Future<List<Topic>> byDish(int dishId, {CancelToken? cancelToken}) async {
    final items = await _api.byFood(dishId, cancelToken: cancelToken);
    return [for (final dto in items) ?_topic(dto)]
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  }

  static Topic? _topic(TopicSummaryDto dto) {
    final startsAt = DateTime.tryParse(dto.startsAt ?? '');
    final endsAt = DateTime.tryParse(dto.endsAt ?? '');
    if (dto.id == null || startsAt == null || endsAt == null) return null;
    return Topic(
      id: dto.id!,
      name: dto.name?.trim() ?? '',
      introduction: dto.introduction?.trim() ?? '',
      startsAt: startsAt.toLocal(),
      endsAt: endsAt.toLocal(),
      dishCount: dto.visibleFoodCount ?? 0,
    );
  }

  static Dish _dish(TopicFoodDto dto) {
    final category = DishCategory.fromApi(dto.category);
    final stages = StageColor.values.asNameMap();
    return Dish(
      id: dto.id!,
      name: dto.name?.trim() ?? '',
      shopId: dto.restaurantId ?? 0,
      shopName: _text(dto.restaurantName),
      price: dto.price,
      category: category,
      images: [
        for (final url in dto.pictureUrl ?? const <String>[])
          if (imageUrl(url) case final url?) DishImage(url: url),
      ],
      stage: stages[dto.stageColor] ?? category?.stage ?? StageColor.broth,
      stageAlternates: [
        for (final name in dto.stageAlternates ?? const <String>[])
          ?stages[name],
      ],
      // TODO: 专题菜品接口不返回 `pictureKeys`, 原封面未过审被过滤时客户端无法识别, 导致裁切参数误用到后续图片上. 后端提供封面标记后改为按标记判断.
      crop: CoverCrop(
        centerX: dto.coverCenterX ?? 0.5,
        centerY: dto.coverCenterY ?? 0.5,
        diameter: dto.coverDiameter ?? 1,
      ),
      likes: dto.likesCount ?? 0,
      description: _text(dto.description),
    );
  }

  static String? _text(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

@Riverpod(keepAlive: true)
TopicRepository topicRepository(Ref ref) =>
    TopicRepository(ref.watch(topicApiProvider));
