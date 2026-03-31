// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uploadRawClient)
final uploadRawClientProvider = UploadRawClientProvider._();

final class UploadRawClientProvider
    extends $FunctionalProvider<RequestClient, RequestClient, RequestClient>
    with $Provider<RequestClient> {
  UploadRawClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadRawClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadRawClientHash();

  @$internal
  @override
  $ProviderElement<RequestClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RequestClient create(Ref ref) {
    return uploadRawClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestClient>(value),
    );
  }
}

String _$uploadRawClientHash() => r'3fd597c6c5329f085d6d9889b848e3038aeb9a3e';

@ProviderFor(restaurantSearchHintDataSource)
final restaurantSearchHintDataSourceProvider =
    RestaurantSearchHintDataSourceProvider._();

final class RestaurantSearchHintDataSourceProvider
    extends
        $FunctionalProvider<
          RestaurantSearchHintDataSource,
          RestaurantSearchHintDataSource,
          RestaurantSearchHintDataSource
        >
    with $Provider<RestaurantSearchHintDataSource> {
  RestaurantSearchHintDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restaurantSearchHintDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restaurantSearchHintDataSourceHash();

  @$internal
  @override
  $ProviderElement<RestaurantSearchHintDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestaurantSearchHintDataSource create(Ref ref) {
    return restaurantSearchHintDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestaurantSearchHintDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestaurantSearchHintDataSource>(
        value,
      ),
    );
  }
}

String _$restaurantSearchHintDataSourceHash() =>
    r'c0c17a14f72dc711c4695113dd2c8d47b2d69e00';

@ProviderFor(uploadRepository)
final uploadRepositoryProvider = UploadRepositoryProvider._();

final class UploadRepositoryProvider
    extends
        $FunctionalProvider<
          UploadRepository,
          UploadRepository,
          UploadRepository
        >
    with $Provider<UploadRepository> {
  UploadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadRepositoryHash();

  @$internal
  @override
  $ProviderElement<UploadRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UploadRepository create(Ref ref) {
    return uploadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadRepository>(value),
    );
  }
}

String _$uploadRepositoryHash() => r'1d8d3f00611b4e2bf4b756c688e46c64ebf55fef';

@ProviderFor(imageUploadRepository)
final imageUploadRepositoryProvider = ImageUploadRepositoryProvider._();

final class ImageUploadRepositoryProvider
    extends
        $FunctionalProvider<
          ImageUploadRepository,
          ImageUploadRepository,
          ImageUploadRepository
        >
    with $Provider<ImageUploadRepository> {
  ImageUploadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageUploadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageUploadRepositoryHash();

  @$internal
  @override
  $ProviderElement<ImageUploadRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageUploadRepository create(Ref ref) {
    return imageUploadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageUploadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageUploadRepository>(value),
    );
  }
}

String _$imageUploadRepositoryHash() =>
    r'f71dbe111d4716760e0616e401da2978caaff32b';
