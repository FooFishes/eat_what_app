import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('事件名和属性与后端一致，可选属性为空时不发送', () {
    expect(const AppOpenEvent().toProperties(), {'event': 'app_open'});
    expect(
      const PageViewEvent(
        AnalyticsPage.food,
        duration: Duration(seconds: 3),
      ).toProperties(),
      {'event': 'page_view', 'page': 'FOOD', 'durationMs': 3000},
    );
    expect(const PageViewEvent(AnalyticsPage.home).toProperties(), {
      'event': 'page_view',
      'page': 'HOME',
    });
    expect(const DishShuffleEvent().toProperties(), {'event': 'dish_shuffle'});
    expect(const DishDecideEvent(restaurantId: 7, foodId: 1).toProperties(), {
      'event': 'dish_decide',
      'restaurantId': 7,
      'foodId': 1,
    });
    expect(const DishDecideEvent().toProperties(), {'event': 'dish_decide'});
    expect(const NavigateShopEvent(7).toProperties(), {
      'event': 'navigate_shop',
      'restaurantId': 7,
    });
    expect(
      const PublishSuccessEvent(AnalyticsTarget.restaurant).toProperties(),
      {'event': 'publish_success', 'kind': 'RESTAURANT'},
    );
    expect(const CommentSuccessEvent().toProperties(), {
      'event': 'comment_success',
    });
    expect(const VerifySuccessEvent(AnalyticsVerifyMethod.sso).toProperties(), {
      'event': 'verify_success',
      'method': 'sso',
    });
    expect(const ShareEvent(AnalyticsTarget.food, 1).toProperties(), {
      'event': 'share',
      'targetType': 'FOOD',
      'targetId': 1,
    });
    expect(
      const LoadFailedEvent(AnalyticsPage.search, code: 500).toProperties(),
      {'event': 'load_failed', 'page': 'SEARCH', 'code': 500},
    );
  });
}
