// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cancellationRepository)
final cancellationRepositoryProvider = CancellationRepositoryProvider._();

final class CancellationRepositoryProvider
    extends
        $FunctionalProvider<
          CancellationRepository,
          CancellationRepository,
          CancellationRepository
        >
    with $Provider<CancellationRepository> {
  CancellationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cancellationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cancellationRepositoryHash();

  @$internal
  @override
  $ProviderElement<CancellationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CancellationRepository create(Ref ref) {
    return cancellationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CancellationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CancellationRepository>(value),
    );
  }
}

String _$cancellationRepositoryHash() =>
    r'dd9c751ab63616e5355453026b8a1ff3b8c0c5ed';
