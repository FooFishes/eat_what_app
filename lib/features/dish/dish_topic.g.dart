// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_topic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 收录过这道菜的专题中最近开始的一个. 没有收录过时为 null.

@ProviderFor(dishTopic)
final dishTopicProvider = DishTopicFamily._();

/// 收录过这道菜的专题中最近开始的一个. 没有收录过时为 null.

final class DishTopicProvider
    extends $FunctionalProvider<AsyncValue<Topic?>, Topic?, FutureOr<Topic?>>
    with $FutureModifier<Topic?>, $FutureProvider<Topic?> {
  /// 收录过这道菜的专题中最近开始的一个. 没有收录过时为 null.
  DishTopicProvider._({
    required DishTopicFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dishTopicProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dishTopicHash();

  @override
  String toString() {
    return r'dishTopicProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Topic?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Topic?> create(Ref ref) {
    final argument = this.argument as int;
    return dishTopic(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DishTopicProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dishTopicHash() => r'1e3d123828599740206e36a7ca183e2994828023';

/// 收录过这道菜的专题中最近开始的一个. 没有收录过时为 null.

final class DishTopicFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Topic?>, int> {
  DishTopicFamily._()
    : super(
        retry: null,
        name: r'dishTopicProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 收录过这道菜的专题中最近开始的一个. 没有收录过时为 null.

  DishTopicProvider call(int dishId) =>
      DishTopicProvider._(argument: dishId, from: this);

  @override
  String toString() => r'dishTopicProvider';
}
