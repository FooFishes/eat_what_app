// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
