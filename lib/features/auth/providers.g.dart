// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tokenStorageDataSource)
final tokenStorageDataSourceProvider = TokenStorageDataSourceProvider._();

final class TokenStorageDataSourceProvider
    extends
        $FunctionalProvider<
          TokenStorageDataSource,
          TokenStorageDataSource,
          TokenStorageDataSource
        >
    with $Provider<TokenStorageDataSource> {
  TokenStorageDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStorageDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStorageDataSourceHash();

  @$internal
  @override
  $ProviderElement<TokenStorageDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TokenStorageDataSource create(Ref ref) {
    return tokenStorageDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStorageDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStorageDataSource>(value),
    );
  }
}

String _$tokenStorageDataSourceHash() =>
    r'7fde62ee3b93f1a071a11ad15e45655a088e4430';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'e82a0119bc3424f9eda913500c4cbfe7dffe3649';
