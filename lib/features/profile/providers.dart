import 'package:eat_what_app/core/network/network_providers.dart';
import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/features/profile/data/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
RequestClient userRawClient(Ref ref) {
  return RequestClient.raw();
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return UserRepository(
    api: ref.read(apiProvider),
    rawApi: ref.read(userRawClientProvider),
  );
}
