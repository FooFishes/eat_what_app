import 'dart:async';

import 'package:eat_what_app/provider/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/api/request_client.dart';

part 'api_provider.g.dart';

@Riverpod(keepAlive: true)
RequestClient api(Ref ref) {
  return RequestClient(
    getToken: () => ref.read(authProvider.notifier).getToken(),
    onRequireReLogin: () {
      ref.read(authProvider.notifier).clearSession().ignore();
    },
  );
}
