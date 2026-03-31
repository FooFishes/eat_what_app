// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_history_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [targetType] is 'restaurant' or 'food'.

@ProviderFor(ProfileHistoryViewModel)
final profileHistoryViewModelProvider = ProfileHistoryViewModelFamily._();

/// [targetType] is 'restaurant' or 'food'.
final class ProfileHistoryViewModelProvider
    extends $NotifierProvider<ProfileHistoryViewModel, ProfileHistoryState> {
  /// [targetType] is 'restaurant' or 'food'.
  ProfileHistoryViewModelProvider._({
    required ProfileHistoryViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profileHistoryViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileHistoryViewModelHash();

  @override
  String toString() {
    return r'profileHistoryViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProfileHistoryViewModel create() => ProfileHistoryViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileHistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileHistoryState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileHistoryViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileHistoryViewModelHash() =>
    r'e4859830743f9b3471c6a472ba3c79306dfa653a';

/// [targetType] is 'restaurant' or 'food'.

final class ProfileHistoryViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfileHistoryViewModel,
          ProfileHistoryState,
          ProfileHistoryState,
          ProfileHistoryState,
          String
        > {
  ProfileHistoryViewModelFamily._()
    : super(
        retry: null,
        name: r'profileHistoryViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [targetType] is 'restaurant' or 'food'.

  ProfileHistoryViewModelProvider call(String targetType) =>
      ProfileHistoryViewModelProvider._(argument: targetType, from: this);

  @override
  String toString() => r'profileHistoryViewModelProvider';
}

/// [targetType] is 'restaurant' or 'food'.

abstract class _$ProfileHistoryViewModel
    extends $Notifier<ProfileHistoryState> {
  late final _$args = ref.$arg as String;
  String get targetType => _$args;

  ProfileHistoryState build(String targetType);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfileHistoryState, ProfileHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileHistoryState, ProfileHistoryState>,
              ProfileHistoryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
