// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_vocabulary.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 口味词表，运营维护，整个 App 用一份。加标签面板和发布时选标签都用它。

@ProviderFor(tasteVocabulary)
final tasteVocabularyProvider = TasteVocabularyProvider._();

/// 口味词表，运营维护，整个 App 用一份。加标签面板和发布时选标签都用它。

final class TasteVocabularyProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TasteTag>>,
          List<TasteTag>,
          FutureOr<List<TasteTag>>
        >
    with $FutureModifier<List<TasteTag>>, $FutureProvider<List<TasteTag>> {
  /// 口味词表，运营维护，整个 App 用一份。加标签面板和发布时选标签都用它。
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

String _$tasteVocabularyHash() => r'b306fa1480ed47ce2fab8cc87ebc7c7528f89ca2';
