import 'package:eat/data/sessions/session_rotation.dart';
import 'package:eat/data/sessions/sessions_api.dart';
import 'package:flutter_test/flutter_test.dart';

SessionOutcomeDto _outcome(String status) => SessionOutcomeDto(
  status: status,
  tokenName: 'satoken',
  tokenValue: 'new',
  restricted: false,
);

void main() {
  test('换发还没完成时再取, 就绪后返回新凭证', () async {
    final replies = [
      _outcome('COMMITTED'),
      _outcome('FACT_READY'),
      _outcome('READY'),
    ];
    var calls = 0;
    final result = await awaitRotation(
      () async => replies[calls++],
      interval: Duration.zero,
    );
    expect(calls, 3);
    expect(result, isA<RotationReady>());
    expect((result as RotationReady).token.value, 'new');
  });

  test('被取代或过期时不再重试, 要重新登录', () async {
    var calls = 0;
    final result = await awaitRotation(() async {
      calls++;
      return _outcome('SUPERSEDED');
    }, interval: Duration.zero);
    expect(result, isA<RotationNeedsSignIn>());
    expect(calls, 1);
  });

  test('次数用完仍未就绪, 要重新登录', () async {
    var calls = 0;
    final result = await awaitRotation(
      () async {
        calls++;
        return _outcome('COMMITTED');
      },
      attempts: 3,
      interval: Duration.zero,
    );
    expect(calls, 3);
    expect(result, isA<RotationNeedsSignIn>());
  });
}
