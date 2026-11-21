import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('业务码归类', () {
    expect(failureKindOf(10003), FailureKind.tooFrequent);
    expect(failureKindOf(20001), FailureKind.sessionExpired);
    expect(failureKindOf(20004), FailureKind.forbidden);
    expect(failureKindOf(30005), FailureKind.business);
    expect(failureKindOf(40008), FailureKind.business);
    expect(failureKindOf(90004), FailureKind.server);
    for (final code in [20005, 20009, 30002, 30006, 30008, 30009]) {
      expect(failureKindOf(code), FailureKind.business, reason: '$code');
    }
    expect(
      failureKindOf(40001),
      FailureKind.unknown,
      reason: '含义随接口而定, 原因写在 msg 里',
    );
    expect(failureKindOf('SITE_ENROLLMENT_REQUIRED'), FailureKind.unknown);
  });

  test('限流按服务端给的秒数提示何时重试', () {
    AppFailure limited(Object? data) =>
        AppFailure.fromCode(BizCodes.tooFrequent, data: data);

    expect(limited(null).retryAfter, isNull);
    expect(limited(null).message, '操作过于频繁，请稍后再试');
    expect(limited({'retryAfterSeconds': 30}).retryHint, '请 30 秒后再试');
    expect(limited({'retryAfterSeconds': 61}).retryHint, '请 2 分钟后再试');
    expect(limited({'retryAfterSeconds': 900}).message, '操作过于频繁，请 15 分钟后再试');
    expect(limited({'retryAfterSeconds': 3600}).retryHint, '请 60 分钟后再试');
    expect(limited({'retryAfterSeconds': 30000}).retryHint, '请 9 小时后再试');
    expect(limited({'retryAfterSeconds': 0}).retryAfter, isNull);
    expect(limited({'retryAfterSeconds': 'x'}).retryAfter, isNull);
  });

  test('提示用规范短句，不带错误码和口语词', () {
    final messages = [
      ...failureMessages.values,
      for (final kind in FailureKind.values) AppFailure(kind).message,
    ];
    for (final message in messages) {
      expect(message, isNot(matches(RegExp(r'\d{4,}'))), reason: message);
      for (final word in ['一下', '吧', '开小差', '！', '!']) {
        expect(message, isNot(contains(word)), reason: message);
      }
    }
  });

  test('密码登录的失败统一说账号或密码错误，不透露是哪一个错了', () {
    expect(AppFailure.fromCode(BizCodes.wrongPassword).message, '账号或密码错误');
  });

  group('服务端写给用户的原因', () {
    test('去掉默认文案前缀', () {
      expect(
        userFacingMessage(40002, '当前状态不允许该操作：每家店最多 3 个招牌菜，请先取消一个'),
        '每家店最多 3 个招牌菜，请先取消一个',
      );
      expect(userFacingMessage(40001, '操作失败：手机号已被其他账号使用'), '手机号已被其他账号使用');
      expect(userFacingMessage(10002, '参数缺失：评论内容和图片至少要有一样'), '评论内容和图片至少要有一样');
      expect(userFacingMessage(10001, ' 说明里不能放链接和联系方式 '), '说明里不能放链接和联系方式');
    });

    test('只有默认文案或为空时不用', () {
      for (final (code, msg) in [
        (10001, '参数非法'),
        (10002, '参数缺失'),
        (10003, '请求频率过高'),
        (40001, '操作失败'),
        (40002, '当前状态不允许该操作'),
        (40004, '重复提交'),
        (40002, '当前状态不允许该操作：'),
        (10001, ''),
        (10001, null),
      ]) {
        expect(userFacingMessage(code, msg), isNull, reason: '$code $msg');
      }
    });

    test('带字段名、枚举值或英文的不用，图片格式和大小单位除外', () {
      for (final msg in [
        'contentType不能为空',
        'kind 只能是 food、drink、buffet',
        'POI 格式不正确',
        '生日格式应为 yyyy-MM-dd',
        'must not be blank',
        '请使用 application/json',
      ]) {
        expect(userFacingMessage(10001, msg), isNull, reason: msg);
      }
      expect(userFacingMessage(10002, '参数缺失：restaurantId不能为空'), isNull);
      expect(userFacingMessage(10001, '文件不能超过 10MB'), '文件不能超过 10MB');
      expect(
        userFacingMessage(10001, '只支持 JPG、PNG、WebP、GIF 图片'),
        '只支持 JPG、PNG、WebP、GIF 图片',
      );
    });

    test('写给开发者看、用词不对或说不清的不用', () {
      for (final (code, msg) in [
        (10001, '不能为空'),
        (10001, '此场景的手机号由服务器确定'),
        (40001, '操作失败：设备会话不存在'),
        (40004, '重复提交：设备令牌刚被登记，请重试'),
        (10001, '通知不存在'),
        (10002, '参数缺失：缺少经纬度'),
        (10001, '页面地址不合法'),
        (10001, '短信验证码与号码核验凭据只能提供一种'),
        (10002, '参数缺失：请提供短信验证码或号码核验凭据'),
        (40008, '菜品不存在'),
        (40009, '餐厅不存在'),
        (40010, '商场不存在'),
        (30017, '账号注销中'),
        (30006, '该用户已通过邮箱验证'),
      ]) {
        expect(userFacingMessage(code, msg), isNull, reason: msg);
      }
    });

    test('带口语词或感叹号的不用', () {
      expect(userFacingMessage(40016, '这家已经有这道菜了，去已有的菜品看看吧'), isNull);
      expect(userFacingMessage(30010, '这个号码还没设密码，用验证码登录吧'), isNull);
      expect(userFacingMessage(10001, '请稍等一下'), isNull);
      expect(userFacingMessage(10001, '发布成功！'), isNull);
      expect(
        userFacingMessage(30010, '还没有设置过密码，请通过手机验证码设置密码'),
        '还没有设置过密码，请通过手机验证码设置密码',
      );
    });

    test('山大邮箱的域名不算拉丁字母', () {
      const sdu = '仅支持山东大学邮箱（@sdu.edu.cn 或 @mail.sdu.edu.cn）';
      expect(userFacingMessage(30009, sdu), sdu);
      expect(userFacingMessage(30007, '邮箱格式不正确 a@qq.com'), isNull);
    });

    test('第三方服务的码去掉默认文案前缀，只有默认文案时不用', () {
      expect(userFacingMessage(50001, '第三方服务不可用：短信服务不可用'), '短信服务不可用');
      expect(userFacingMessage(50002, '第三方接口超时：短信服务请求超时'), '短信服务请求超时');
      for (final (code, msg) in [
        (50001, '第三方服务不可用'),
        (50002, '第三方接口超时'),
        (50003, '第三方返回异常'),
      ]) {
        expect(userFacingMessage(code, msg), isNull, reason: msg);
      }
      expect(userFacingMessage(50004, '人机验证服务暂不可用，请稍后重试'), '人机验证服务暂不可用，请稍后重试');
    });

    test('码表里的码也用服务端的原因', () {
      for (final (code, msg) in [
        (30005, '验证码错误'),
        (30003, '用户名已存在'),
        (30004, '密码错误'),
        (30011, '还没有绑定手机号'),
        (30017, '账号注销中，在申请注销的设备上重新登录可以撤销'),
        (20009, '隐私政策或数据跨境说明已更新，请重新阅读并同意'),
        (30018, '这个号码不是本机号码，请使用短信验证'),
      ]) {
        expect(userFacingMessage(code, msg), msg, reason: '$code');
      }
    });

    test('客户端另有流程或文案不对的码不用 msg', () {
      for (final (code, msg) in [
        (20001, '用户未登录'),
        (20002, 'Token 无效'),
        (20004, '权限不足：对方没有公开粉丝列表'),
        (20007, '身份验证暂不可用'),
        (30002, '账号封禁中，暂时不能进行这个操作'),
        (40017, '这家店已经有了'),
        (10004, '不支持的操作：接口不存在'),
        (90001, '系统内部异常'),
        (90004, '未捕获异常'),
      ]) {
        expect(userFacingMessage(code, msg), isNull, reason: '$code');
      }
    });

    test('服务端的原因只用于业务错误、未知错误和限流', () {
      for (final kind in [
        FailureKind.network,
        FailureKind.server,
        FailureKind.sessionExpired,
        FailureKind.forbidden,
        FailureKind.cancelled,
      ]) {
        final failure = AppFailure(kind, userMessage: '服务端的原因');
        expect(failure.message, isNot('服务端的原因'), reason: '$kind');
      }
      expect(
        const AppFailure(
          FailureKind.business,
          code: 30005,
          userMessage: '验证码错误',
        ).message,
        '验证码错误',
      );
    });

    test('限流时具体的原因照样显示，结尾的「请稍后再试」换成等待时间', () {
      AppFailure limited(String msg, [Object? data]) => AppFailure(
        FailureKind.tooFrequent,
        code: BizCodes.tooFrequent,
        serverMessage: msg,
        data: data,
        userMessage: userFacingMessage(BizCodes.tooFrequent, msg),
      );

      expect(limited('请求频率过高').message, '操作过于频繁，请稍后再试');
      expect(
        limited('请求频率过高', {'retryAfterSeconds': 900}).message,
        '操作过于频繁，请 15 分钟后再试',
      );
      expect(limited('今日发布已达上限，请明天再试').message, '今日发布已达上限，请明天再试');
      expect(
        limited('今日发布已达上限，请明天再试', {'retryAfterSeconds': 900}).message,
        '今日发布已达上限，请明天再试',
      );
      const restricted = '操作过于频繁，已暂时限制赞、收藏和关注，请稍后再试';
      expect(limited(restricted).message, restricted);
      expect(
        limited(restricted, {'retryAfterSeconds': 1800}).message,
        '操作过于频繁，已暂时限制赞、收藏和关注，请 30 分钟后再试',
      );
    });
  });
}
