// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackCaseDto _$FeedbackCaseDtoFromJson(Map<String, dynamic> json) =>
    FeedbackCaseDto(
      id: (json['id'] as num?)?.toInt(),
      kind: json['kind'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String?,
      target: json['target'] == null
          ? null
          : FeedbackTargetDto.fromJson(json['target'] as Map<String, dynamic>),
      reason: json['reason'] as String?,
      text: json['text'] as String?,
      screenshots: (json['screenshots'] as List<dynamic>?)
          ?.map(
            (e) => FeedbackScreenshotDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      outcome: json['outcome'] as String?,
      reply: json['reply'] as String?,
      createdAt: (json['createdAt'] as num?)?.toInt(),
      closedAt: (json['closedAt'] as num?)?.toInt(),
    );

FeedbackTargetDto _$FeedbackTargetDtoFromJson(Map<String, dynamic> json) =>
    FeedbackTargetDto(
      type: json['type'] as String?,
      id: (json['id'] as num?)?.toInt(),
    );

FeedbackScreenshotDto _$FeedbackScreenshotDtoFromJson(
  Map<String, dynamic> json,
) => FeedbackScreenshotDto(
  slot: (json['slot'] as num?)?.toInt(),
  url: json['url'] as String?,
);

Map<String, dynamic> _$CatalogErrorDtoToJson(CatalogErrorDto instance) =>
    <String, dynamic>{
      'restaurantId': instance.restaurantId,
      'errorType': instance.errorType,
      'note': ?instance.note,
    };

Map<String, dynamic> _$ReportDtoToJson(ReportDto instance) => <String, dynamic>{
  'targetType': instance.targetType,
  'targetId': instance.targetId,
  'reason': instance.reason,
  'note': ?instance.note,
};

Map<String, dynamic> _$FeedbackMessageDtoToJson(FeedbackMessageDto instance) =>
    <String, dynamic>{
      'text': instance.text,
      'category': instance.category,
      'screenshotKeys': ?instance.screenshotKeys,
      'context': ?instance.context?.toJson(),
    };

Map<String, dynamic> _$FeedbackContextDtoToJson(FeedbackContextDto instance) =>
    <String, dynamic>{'type': instance.type, 'id': instance.id};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedbackApi)
final feedbackApiProvider = FeedbackApiProvider._();

final class FeedbackApiProvider
    extends $FunctionalProvider<FeedbackApi, FeedbackApi, FeedbackApi>
    with $Provider<FeedbackApi> {
  FeedbackApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackApiHash();

  @$internal
  @override
  $ProviderElement<FeedbackApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeedbackApi create(Ref ref) {
    return feedbackApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedbackApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedbackApi>(value),
    );
  }
}

String _$feedbackApiHash() => r'631265f5768edb39ef56e1c4374b020525587868';
