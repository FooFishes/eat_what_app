// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeleteAccount)
final deleteAccountProvider = DeleteAccountProvider._();

final class DeleteAccountProvider
    extends $NotifierProvider<DeleteAccount, DeleteAccountState> {
  DeleteAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountHash();

  @$internal
  @override
  DeleteAccount create() => DeleteAccount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteAccountState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteAccountState>(value),
    );
  }
}

String _$deleteAccountHash() => r'79628ee9c5f56d660c50f8615982dcff2e578354';

abstract class _$DeleteAccount extends $Notifier<DeleteAccountState> {
  DeleteAccountState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DeleteAccountState, DeleteAccountState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeleteAccountState, DeleteAccountState>,
              DeleteAccountState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
