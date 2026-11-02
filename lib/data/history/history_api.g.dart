// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrowseItemDto _$BrowseItemDtoFromJson(Map<String, dynamic> json) =>
    BrowseItemDto(
      targetType: json['targetType'] as String?,
      targetId: (json['targetId'] as num?)?.toInt(),
      viewedAt: (json['viewedAt'] as num?)?.toInt(),
      food: json['food'] == null
          ? null
          : BrowseTargetDto.fromJson(json['food'] as Map<String, dynamic>),
      restaurant: json['restaurant'] == null
          ? null
          : BrowseTargetDto.fromJson(
              json['restaurant'] as Map<String, dynamic>,
            ),
    );

BrowseTargetDto _$BrowseTargetDtoFromJson(Map<String, dynamic> json) =>
    BrowseTargetDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      pictureUrl: (json['pictureUrl'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likesCount: (json['likesCount'] as num?)?.toInt(),
    );

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(historyApi)
final historyApiProvider = HistoryApiProvider._();

final class HistoryApiProvider
    extends $FunctionalProvider<HistoryApi, HistoryApi, HistoryApi>
    with $Provider<HistoryApi> {
  HistoryApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyApiHash();

  @$internal
  @override
  $ProviderElement<HistoryApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryApi create(Ref ref) {
    return historyApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryApi>(value),
    );
  }
}

String _$historyApiHash() => r'1c796a443fadccd9d0b6175194436a160bfa429b';
