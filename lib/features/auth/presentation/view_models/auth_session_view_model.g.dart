// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthSessionViewModel)
final authSessionViewModelProvider = AuthSessionViewModelProvider._();

final class AuthSessionViewModelProvider
    extends $AsyncNotifierProvider<AuthSessionViewModel, String?> {
  AuthSessionViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionViewModelHash();

  @$internal
  @override
  AuthSessionViewModel create() => AuthSessionViewModel();
}

String _$authSessionViewModelHash() =>
    r'3b337f14aadc56758306af9fa0e6db8dd9d9dc49';

abstract class _$AuthSessionViewModel extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
