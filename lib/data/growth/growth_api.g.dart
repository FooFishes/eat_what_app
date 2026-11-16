// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'growth_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrowthProgressDto _$GrowthProgressDtoFromJson(Map<String, dynamic> json) =>
    GrowthProgressDto(
      level: (json['level'] as num?)?.toInt(),
      experience: (json['experience'] as num?)?.toInt(),
      levelExperience: (json['levelExperience'] as num?)?.toInt(),
      nextLevel: (json['nextLevel'] as num?)?.toInt(),
      nextLevelExperience: (json['nextLevelExperience'] as num?)?.toInt(),
      toNextLevel: (json['toNextLevel'] as num?)?.toInt(),
      maxLevel: json['maxLevel'] as bool?,
      dailyUseExperience: (json['dailyUseExperience'] as num?)?.toInt(),
      title: json['title'] as String?,
      rules: (json['rules'] as List<dynamic>?)
          ?.map((e) => ExperienceRuleDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

ExperienceRuleDto _$ExperienceRuleDtoFromJson(Map<String, dynamic> json) =>
    ExperienceRuleDto(
      source: json['source'] as String?,
      name: json['name'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      dailyCap: (json['dailyCap'] as num?)?.toInt(),
    );

ExperienceEntryDto _$ExperienceEntryDtoFromJson(Map<String, dynamic> json) =>
    ExperienceEntryDto(
      id: (json['id'] as num?)?.toInt(),
      source: json['source'] as String?,
      sourceName: json['sourceName'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      day: json['day'] as String?,
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
