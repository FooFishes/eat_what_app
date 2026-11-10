// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'growth_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrowthProgressDto _$GrowthProgressDtoFromJson(Map<String, dynamic> json) =>
    GrowthProgressDto(
      totalExperience: (json['totalExperience'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      levelStartExperience: (json['levelStartExperience'] as num?)?.toInt(),
      nextLevelExperience: (json['nextLevelExperience'] as num?)?.toInt(),
      experienceToNextLevel: (json['experienceToNextLevel'] as num?)?.toInt(),
      maxLevel: json['maxLevel'] as bool?,
      dailyExperience: (json['dailyExperience'] as num?)?.toInt(),
    );

ExperienceEntryDto _$ExperienceEntryDtoFromJson(Map<String, dynamic> json) =>
    ExperienceEntryDto(
      entryId: json['entryId'] as String?,
      businessDate: json['businessDate'] as String?,
      sourceType: json['sourceType'] as String?,
      experience: (json['experience'] as num?)?.toInt(),
    );

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(growthApi)
final growthApiProvider = GrowthApiProvider._();

final class GrowthApiProvider
    extends $FunctionalProvider<GrowthApi, GrowthApi, GrowthApi>
    with $Provider<GrowthApi> {
  GrowthApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'growthApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$growthApiHash();

  @$internal
  @override
  $ProviderElement<GrowthApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GrowthApi create(Ref ref) {
    return growthApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrowthApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrowthApi>(value),
    );
  }
}

String _$growthApiHash() => r'65ec7d7b5896aa561afb462c00eac0f735c7332f';
