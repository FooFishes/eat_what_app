import 'package:clock/clock.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/topic/topic_repository.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/domain/models/topic.dart';
import 'package:eat/domain/rules/topic_rules.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_topic.g.dart';

/// 收录过这道菜的专题中最近开始的一个. 没有收录过时为 null.
@riverpod
Future<Topic?> dishTopic(Ref ref, int dishId) async {
  ref.cacheFor(const Duration(minutes: 5));
  final topics = await ref
      .watch(topicRepositoryProvider)
      .byDish(dishId, cancelToken: ref.cancelToken());
  return topics.firstOrNull;
}

/// 菜品详情店卡下的专题提示, 如 "收进了本周专题「期末续命餐」", 点击进入专题页.
///
/// 没有收录过, 加载中或请求失败时不占位. 提示是附加信息, 失败不影响详情的其余部分.
class DishTopicHint extends ConsumerWidget {
  const new({super.key, required this.dishId});

  final int dishId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = ref.watch(dishTopicProvider(dishId)).value;
    if (topic == null) return const SizedBox.shrink();
    final eat = context.eat;
    final text = TopicRules.dishHint(topic, clock.now());
    return Padding(
      padding: const EdgeInsets.only(top: EatSpace.s4),
      child: EatTappable(
        onTap: () => context.push(Paths.topic(topic.id)),
        label: text,
        button: false,
        focusShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        builder: (context, _) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: EatSize.touch),
          child: Row(
            spacing: EatSpace.s8,
            children: [
              EatIcon(EatIcons.topic, size: 18, color: eat.colors.ink),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.body.copyWith(color: eat.colors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
