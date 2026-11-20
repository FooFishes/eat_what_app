import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'taste_vocabulary.g.dart';

// TODO: 只有加标签面板仍按旧的口味词表使用本 Provider, 加菜页已直接使用 [Taste]. 面板随口味投票一起待接入, 没有入口. 面板改为直接使用 [Taste] 后删除本 Provider.
/// 可选的口味, 以 [TasteTag] 的形式提供, [TasteTag.id] 是 [Taste.index].
///
/// 后端 v2 的口味固定为 [Taste] 的五个值, 删除了口味词表接口, 因此不发请求.
@Riverpod(keepAlive: true)
Future<List<TasteTag>> tasteVocabulary(Ref ref) async => [
  for (final taste in Taste.values)
    TasteTag(id: taste.index, name: taste.label),
];
