import 'package:eat/core/network/auth_token.dart';
import 'package:eat/data/sessions/sessions_api.dart';

/// 换发会话的结果: 下线其他设备和换绑手机后, 服务端为本机换发新会话.
sealed class Rotation {
  const Rotation();
}

/// 换发完成, [token] 是本机的新凭证. [restricted] 表示新会话是封禁中的受限会话.
final class RotationReady extends Rotation {
  const RotationReady(this.token, {this.restricted = false});

  final AuthToken token;
  final bool restricted;
}

/// 未能获取新凭证, 本机需要重新登录.
final class RotationNeedsSignIn extends Rotation {
  const RotationNeedsSignIn();
}

/// 反复调用 [resume] 直到换发完成, 最多 [attempts] 次, 每次间隔 [interval].
///
/// 换发由服务端异步完成, 刚提交时状态通常为 `COMMITTED`. 次数用尽仍未完成时按需要重新登录处理.
Future<Rotation> awaitRotation(
  Future<SessionOutcomeDto> Function() resume, {
  int attempts = 5,
  Duration interval = const Duration(seconds: 1),
}) async {
  for (var i = 0; i < attempts; i++) {
    final outcome = await resume();
    if (rotationOf(outcome) case final ready?) return ready;
    if (outcome.status case 'SUPERSEDED' || 'EXPIRED') break;
    if (i < attempts - 1) await Future<void>.delayed(interval);
  }
  return const RotationNeedsSignIn();
}

/// [outcome] 已就绪时的结果, 否则为 null.
RotationReady? rotationOf(SessionOutcomeDto? outcome) {
  if (outcome == null || outcome.status != 'READY') return null;
  final name = outcome.tokenName;
  final value = outcome.tokenValue;
  if (name == null || name.isEmpty || value == null || value.isEmpty) {
    return null;
  }
  return RotationReady(
    AuthToken(name: name, value: value),
    restricted: outcome.restricted ?? false,
  );
}
