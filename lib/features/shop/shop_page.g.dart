// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 一家店的全部菜，按赞数排。招牌、菜数、口味汇总都从它算：接口还没有这些汇总字段（现状差距 2.1）。

@ProviderFor(shopMenu)
final shopMenuProvider = ShopMenuFamily._();

/// 一家店的全部菜，按赞数排。招牌、菜数、口味汇总都从它算：接口还没有这些汇总字段（现状差距 2.1）。

final class ShopMenuProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Dish>>,
          List<Dish>,
          FutureOr<List<Dish>>
        >
    with $FutureModifier<List<Dish>>, $FutureProvider<List<Dish>> {
  /// 一家店的全部菜，按赞数排。招牌、菜数、口味汇总都从它算：接口还没有这些汇总字段（现状差距 2.1）。
  ShopMenuProvider._({
    required ShopMenuFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shopMenuProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shopMenuHash();

  @override
  String toString() {
    return r'shopMenuProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Dish>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Dish>> create(Ref ref) {
    final argument = this.argument as int;
    return shopMenu(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopMenuProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shopMenuHash() => r'0f7e4dc733b252da7722ccb4c2947d32c05f63ca';

/// 一家店的全部菜，按赞数排。招牌、菜数、口味汇总都从它算：接口还没有这些汇总字段（现状差距 2.1）。

final class ShopMenuFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Dish>>, int> {
  ShopMenuFamily._()
    : super(
        retry: null,
        name: r'shopMenuProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一家店的全部菜，按赞数排。招牌、菜数、口味汇总都从它算：接口还没有这些汇总字段（现状差距 2.1）。

  ShopMenuProvider call(int shopId) =>
      ShopMenuProvider._(argument: shopId, from: this);

  @override
  String toString() => r'shopMenuProvider';
}
