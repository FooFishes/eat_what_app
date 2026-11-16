import 'package:dio/dio.dart';
import 'package:eat/data/recommend/preference_api.dart';
import 'package:eat/data/recommend/preference_dto.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/recommend_preferences.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preference_repository.g.dart';

/// 推荐偏好仓库, 负责把接口里的品类, 口味和价位字符串转换为客户端枚举.
///
/// 后端的品类和口味只在末尾追加, 客户端不认识的值直接丢弃.
class PreferenceRepository {
  PreferenceRepository(this._api);

  final PreferenceApi _api;

  Future<RecommendPreferences> preferences({CancelToken? cancelToken}) async =>
      _preferences(await _api.preferences(cancelToken: cancelToken));

  /// 整体覆盖推荐偏好, 返回服务端保存后的结果.
  Future<RecommendPreferences> save(RecommendPreferences next) async =>
      _preferences(
        await _api.save(
          PreferencesRequestDto(
            likedCategories: [
              for (final c in ShopCategory.values)
                if (next.likedCategories.contains(c)) c.api,
            ],
            likedTags: [
              for (final t in Taste.values)
                if (next.likedTastes.contains(t)) t.api,
            ],
            dislikedTags: [
              for (final t in Taste.values)
                if (next.dislikedTastes.contains(t)) t.api,
            ],
            priceBand: next.priceBand?.api,
            maxDistance: next.maxDistance,
          ),
        ),
      );

  Future<void> clear() => _api.clear();

  Future<TasteProfile> taste({CancelToken? cancelToken}) async {
    final dto = await _api.taste(cancelToken: cancelToken);
    return TasteProfile(
      inferredTastes: _tastes(dto.inferredTags),
      inferredCategories: _categories(dto.inferredCategories),
    );
  }

  Future<RecommendOptions> options({CancelToken? cancelToken}) async {
    final dto = await _api.options(cancelToken: cancelToken);
    return RecommendOptions(
      categories: _categories(dto.categories),
      tastes: _tastes(dto.tags),
      dislikable: _tastes(dto.dislikableTags),
    );
  }

  static RecommendPreferences _preferences(PreferencesDto dto) =>
      RecommendPreferences(
        likedCategories: _categories(dto.likedCategories).toSet(),
        likedTastes: _tastes(dto.likedTags).toSet(),
        dislikedTastes: _tastes(dto.dislikedTags).toSet(),
        priceBand: PriceBand.fromApi(dto.priceBand),
        maxDistance: dto.maxDistance,
      );

  static List<ShopCategory> _categories(List<String>? values) => [
    for (final v in values ?? const <String>[]) ?ShopCategory.fromApi(v),
  ];

  static List<Taste> _tastes(List<String>? values) => [
    for (final v in values ?? const <String>[]) ?Taste.fromApi(v),
  ];
}

@Riverpod(keepAlive: true)
PreferenceRepository preferenceRepository(Ref ref) =>
    PreferenceRepository(ref.watch(preferenceApiProvider));
