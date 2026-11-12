// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_vocabulary.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 可选的口味, 以 [TasteTag] 的形式提供, [TasteTag.id] 是 [Taste.index].
///
/// 后端 v2 的口味固定为 [Taste] 的五个值, 删除了口味词表接口, 因此不发请求.

@ProviderFor(tasteVocabulary)
final tasteVocabularyProvider = TasteVocabularyProvider._();

/// 可选的口味, 以 [TasteTag] 的形式提供, [TasteTag.id] 是 [Taste.index].
///
/// 后端 v2 的口味固定为 [Taste] 的五个值, 删除了口味词表接口, 因此不发请求.

final class TasteVocabularyProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TasteTag>>,
          List<TasteTag>,
          FutureOr<List<TasteTag>>
        >
    with $FutureModifier<List<TasteTag>>, $FutureProvider<List<TasteTag>> {
  /// 可选的口味, 以 [TasteTag] 的形式提供, [TasteTag.id] 是 [Taste.index].
  ///
  /// 后端 v2 的口味固定为 [Taste] 的五个值, 删除了口味词表接口, 因此不发请求.
  TasteVocabularyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tasteVocabularyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tasteVocabularyHash();

  @$internal
  @override
  $FutureProviderElement<List<TasteTag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TasteTag>> create(Ref ref) {
    return tasteVocabulary(ref);
  }
}

String _$tasteVocabularyHash() => r'0a185f0270dc24d59955dbfe98058052e8acb87a';
