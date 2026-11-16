/// 使用统计事件. 事件种类和属性与后端 `TelemetryService.EVENTS` 一一对应, 服务端收到未知事件或属性会拒绝整批.
///
/// 属性只有枚举, id, 整数和时长, 没有自由文本, 从类型上保证不采集输入框内容.
/// 身份和时间由服务端从会话和时钟获取, 安装 ID 随批次发送, 事件本身不带公共属性.
sealed class AnalyticsEvent {
  const AnalyticsEvent();

  /// 服务端的事件名, 即 `properties.event`.
  String get name;

  /// `event` 以外的属性. 值为 null 的可选属性不发送.
  Map<String, Object> get attributes => const {};

  /// 上报时的 `properties`.
  Map<String, Object> toProperties() => {'event': name, ...attributes};
}

/// 统计用的页面分类, 取值与后端一致.
enum AnalyticsPage {
  home('HOME'),
  recommend('RECOMMEND'),
  search('SEARCH'),
  restaurant('RESTAURANT'),
  food('FOOD'),
  message('MESSAGE'),
  profile('PROFILE'),
  other('OTHER');

  const AnalyticsPage(this.wire);

  final String wire;
}

/// 发布或分享的对象: 菜品或店铺.
enum AnalyticsTarget {
  food('FOOD'),
  restaurant('RESTAURANT');

  const AnalyticsTarget(this.wire);

  final String wire;
}

/// 学生认证的方式.
enum AnalyticsVerifyMethod {
  sso('sso'),
  email('email');

  const AnalyticsVerifyMethod(this.wire);

  final String wire;
}

/// 冷启动或回到前台.
final class AppOpenEvent extends AnalyticsEvent {
  const AppOpenEvent();

  @override
  String get name => 'app_open';
}

/// 离开页面时记录, [duration] 为停留时长.
final class PageViewEvent extends AnalyticsEvent {
  const PageViewEvent(this.page, {this.duration});

  final AnalyticsPage page;
  final Duration? duration;

  @override
  String get name => 'page_view';

  @override
  Map<String, Object> get attributes => {
    'page': page.wire,
    if (duration case final d?) 'durationMs': d.inMilliseconds,
  };
}

/// 换一个 (按钮或拖动).
final class DishShuffleEvent extends AnalyticsEvent {
  const DishShuffleEvent();

  @override
  String get name => 'dish_shuffle';
}

/// 就它了.
final class DishDecideEvent extends AnalyticsEvent {
  const DishDecideEvent({this.restaurantId, this.foodId});

  final int? restaurantId;
  final int? foodId;

  @override
  String get name => 'dish_decide';

  @override
  Map<String, Object> get attributes => {
    'restaurantId': ?restaurantId,
    'foodId': ?foodId,
  };
}

/// 导航去店里.
final class NavigateShopEvent extends AnalyticsEvent {
  const NavigateShopEvent(this.restaurantId);

  final int restaurantId;

  @override
  String get name => 'navigate_shop';

  @override
  Map<String, Object> get attributes => {'restaurantId': restaurantId};
}

/// 发布成功.
final class PublishSuccessEvent extends AnalyticsEvent {
  const PublishSuccessEvent(this.kind);

  final AnalyticsTarget kind;

  @override
  String get name => 'publish_success';

  @override
  Map<String, Object> get attributes => {'kind': kind.wire};
}

/// 写评论成功.
final class CommentSuccessEvent extends AnalyticsEvent {
  const CommentSuccessEvent();

  @override
  String get name => 'comment_success';
}

/// 认证成功.
final class VerifySuccessEvent extends AnalyticsEvent {
  const VerifySuccessEvent(this.method);

  final AnalyticsVerifyMethod method;

  @override
  String get name => 'verify_success';

  @override
  Map<String, Object> get attributes => {'method': method.wire};
}

/// 分享.
final class ShareEvent extends AnalyticsEvent {
  const ShareEvent(this.targetType, this.targetId);

  final AnalyticsTarget targetType;
  final int targetId;

  @override
  String get name => 'share';

  @override
  Map<String, Object> get attributes => {
    'targetType': targetType.wire,
    'targetId': targetId,
  };
}

/// 显示了 "加载失败". [code] 为业务码或 HTTP 状态码, 没有时为 null.
final class LoadFailedEvent extends AnalyticsEvent {
  const LoadFailedEvent(this.page, {this.code});

  final AnalyticsPage page;
  final int? code;

  @override
  String get name => 'load_failed';

  @override
  Map<String, Object> get attributes => {'page': page.wire, 'code': ?code};
}
