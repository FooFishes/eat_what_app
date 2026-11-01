import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'taste_vocabulary.g.dart';

/// 口味词表，运营维护，整个 App 用一份。加标签面板和发布时选标签都用它。
@Riverpod(keepAlive: true)
Future<List<TasteTag>> tasteVocabulary(Ref ref) => ref
    .watch(foodRepositoryProvider)
    .tasteVocabulary(cancelToken: ref.cancelToken());
