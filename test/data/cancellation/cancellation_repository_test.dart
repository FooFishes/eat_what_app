import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/cancellation/cancellation_repository.dart';
import 'package:eat/domain/models/cancellation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

const _subject = '11111111-1111-4111-8111-111111111111';
const _request = '22222222-2222-4222-8222-222222222222';
const _capability = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

const _pending = PendingCancellation(
  subjectId: _subject,
  requestId: _request,
  phase: CancellationPhase.preparing,
);

Map<String, Object?> _status(String phase, {String? deadline}) =>
    FakeAdapter.ok({
      'requestId': _request,
      'phase': phase,
      'deadline': deadline,
      'complete': false,
    });

Map<String, Object?> _grant(String operationId) => FakeAdapter.ok({
  'subjectId': _subject,
  'requestId': _request,
  'operationId': operationId,
  'bindingVersion': 1,
  'proofDigest': 'digest',
  'expiresAt': '2026-11-11T08:05:00Z',
});

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  test('申请注销先在本机存下恢复凭据，再带着选择提交', () async {
    env.adapter.on('POST /user/cancellation', [
      _status('PREPARING', deadline: '2026-11-18T08:00:00Z'),
    ]);
    final container = await env.container();
    final repository = container.read(cancellationRepositoryProvider);
    final draft = repository.draft(deleteComments: true);

    final status = await repository.request(draft);

    expect(status.phase, CancellationPhase.preparing);
    expect(status.deadline, DateTime.utc(2026, 11, 18, 8).toLocal());
    final sent = env.adapter.sent('POST /user/cancellation').single;
    expect(sent.body, {
      'requestId': draft.requestId,
      'recoveryCapability': draft.recoveryCapability,
      'deletePostsAndComments': true,
    });
    expect(draft.recoveryCapability, hasLength(43));
    expect(
      env.secure.values['lifecycle.recovery.${draft.requestId}'],
      draft.recoveryCapability,
    );
    expect(draft.toString(), isNot(contains(draft.recoveryCapability)));
  });

  test('申请失败时凭据仍然保留，重试同一份申请还能撤销', () async {
    env.adapter.on('POST /user/cancellation', [const FakeResponse.offline()]);
    final container = await env.container();
    final repository = container.read(cancellationRepositoryProvider);
    final draft = repository.draft(deleteComments: false);

    await expectLater(
      repository.request(draft),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.network),
      ),
    );
    expect(
      env.secure.values['lifecycle.recovery.${draft.requestId}'],
      draft.recoveryCapability,
    );
    expect(
      env.adapter.sent('POST /user/cancellation').single.body,
      containsPair('deletePostsAndComments', false),
    );
  });

  test('本机没有这次申请的凭据时拿不到撤销凭据', () async {
    final container = await env.container();

    expect(
      await container.read(cancellationRepositoryProvider).ticketFor(_pending),
      isNull,
    );
  });

  test('用密码验证后带着操作 id 撤销，凭据放在请求头里，撤销后删掉', () async {
    env.secure.values['lifecycle.recovery.$_request'] = _capability;
    env.adapter
      ..on('POST /user/cancellation/recover/password', [_grant('op-1')])
      ..on('POST /user/cancellation/$_subject/$_request/cancel', [
        _status('ACTIVE'),
      ]);
    final container = await env.container();
    final repository = container.read(cancellationRepositoryProvider);
    final ticket = (await repository.ticketFor(_pending))!;

    final status = await repository.restoreWithPassword(
      ticket,
      identifier: '13812345678',
      password: 'secret-1',
    );

    expect(status.phase, CancellationPhase.active);
    final recover = env.adapter
        .sent('POST /user/cancellation/recover/password')
        .single;
    expect(recover.body, {
      'identifier': '13812345678',
      'password': 'secret-1',
      'subjectId': _subject,
      'requestId': _request,
      'operationId': isA<String>(),
      'recoveryCapability': _capability,
    });
    final cancel = env.adapter
        .sent('POST /user/cancellation/$_subject/$_request/cancel')
        .single;
    expect(cancel.body, {'credentialOperation': 'op-1'});
    expect(cancel.headers['X-Lifecycle-Recovery'], _capability);
    expect(env.secure.values, isNot(contains('lifecycle.recovery.$_request')));
  });

  test('验证码：每次发码换新的操作 id，验证时用最后一次的', () async {
    env.secure.values['lifecycle.recovery.$_request'] = _capability;
    final challenge = FakeAdapter.ok({
      'challengeId': 'c-1',
      'expiresAt': '2026-11-11T08:05:00Z',
    });
    env.adapter
      ..on('POST /user/cancellation/recover/phone/challenge', [challenge])
      ..on('POST /user/cancellation/recover/phone/verify', [_grant('op-2')])
      ..on('POST /user/cancellation/$_subject/$_request/cancel', [
        _status('ACTIVE'),
      ]);
    final container = await env.container();
    final repository = container.read(cancellationRepositoryProvider);
    final ticket = (await repository.ticketFor(_pending))!;

    final first = await repository.sendRestoreCode(ticket);
    final second = await repository.sendRestoreCode(ticket);
    expect(second.operationId, isNot(first.operationId));
    await repository.restoreWithCode(ticket, second, '123456');

    final verify = env.adapter
        .sent('POST /user/cancellation/recover/phone/verify')
        .single;
    expect(verify.body, {
      'code': '123456',
      'subjectId': _subject,
      'requestId': _request,
      'operationId': second.operationId,
      'recoveryCapability': _capability,
    });
    expect(
      env.adapter
          .sent('POST /user/cancellation/$_subject/$_request/cancel')
          .single
          .body,
      {'credentialOperation': 'op-2'},
    );
  });

  test('查询状态凭恢复凭据，不需要登录', () async {
    env.secure.values['lifecycle.recovery.$_request'] = _capability;
    env.adapter.on('POST /user/cancellation/$_subject/$_request/status', [
      _status('PENDING', deadline: '2026-11-18T08:00:00Z'),
    ]);
    final container = await env.container();
    final repository = container.read(cancellationRepositoryProvider);

    final status = await repository.status(
      (await repository.ticketFor(_pending))!,
    );

    expect(status.phase, CancellationPhase.pending);
    expect(status.phase.revocable, isTrue);
    final sent = env.adapter
        .sent('POST /user/cancellation/$_subject/$_request/status')
        .single;
    expect(sent.headers['X-Lifecycle-Recovery'], _capability);
    expect(sent.headers, isNot(contains('satoken')));
  });

  group('pendingCancellationOf', () {
    test('登录返回注销冷静期时读出申请', () {
      final pending = pendingCancellationOf(
        AppFailure.fromCode(
          BizCodes.dataSyncPending,
          data: {
            'recoveryRequired': true,
            'subjectId': _subject,
            'requestId': _request,
            'phase': 'PENDING',
          },
        ),
      );

      expect(pending?.subjectId, _subject);
      expect(pending?.requestId, _request);
      expect(pending?.phase, CancellationPhase.pending);
    });

    test('普通的同步中、别的业务码都不算', () {
      expect(
        pendingCancellationOf(AppFailure.fromCode(BizCodes.dataSyncPending)),
        isNull,
      );
      expect(
        pendingCancellationOf(
          AppFailure.fromCode(
            BizCodes.wrongPassword,
            data: {
              'recoveryRequired': true,
              'subjectId': _subject,
              'requestId': _request,
            },
          ),
        ),
        isNull,
      );
    });
  });
}
