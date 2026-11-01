import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'taste_vocabulary.g.dart';

/// 口味词表, 由运营维护, 全局共用一份. 用于加标签面板和发布时的标签选择.
@Riverpod(keepAlive: true)
Future<List<TasteTag>> tasteVocabulary(Ref ref) => ref
    .watch(foodRepositoryProvider)
    .tasteVocabulary(cancelToken: ref.cancelToken());
