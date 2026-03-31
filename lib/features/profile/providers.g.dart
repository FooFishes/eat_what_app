// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userRawClient)
final userRawClientProvider = UserRawClientProvider._();

final class UserRawClientProvider
    extends $FunctionalProvider<RequestClient, RequestClient, RequestClient>
    with $Provider<RequestClient> {
  UserRawClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRawClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRawClientHash();

  @$internal
  @override
  $ProviderElement<RequestClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RequestClient create(Ref ref) {
    return userRawClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestClient>(value),
    );
  }
}

String _$userRawClientHash() => r'a6016c7d1d57b150a2256827d3debb4fd224e721';

@ProviderFor(userRepository)
final userRepositoryProvider = UserRepositoryProvider._();

final class UserRepositoryProvider
    extends $FunctionalProvider<UserRepository, UserRepository, UserRepository>
    with $Provider<UserRepository> {
  UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'0cfca5cccd15fcdfb429fc0bc96e79ad564d0dd0';
