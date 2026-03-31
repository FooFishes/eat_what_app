import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/features/auth/presentation/view_models/auth_session_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

@Riverpod(keepAlive: true)
RequestClient api(Ref ref) {
  return RequestClient(
    getToken: () => ref.read(authSessionViewModelProvider.notifier).getToken(),
    clearSession: () =>
        ref.read(authSessionViewModelProvider.notifier).clearSession(),
  );
}
