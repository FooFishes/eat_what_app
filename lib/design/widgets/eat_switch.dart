import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:flutter/widgets.dart';

/// 整行可点的开关组件, 左侧显示文字而右侧为开关, 切换后立即生效而不额外配备 "保存" 按钮.
///
/// - 需要二次确认的操作 (如退出登录, 注销账号) 应使用按钮而非开关.
/// - 若关闭后会改变他人所见内容, 需在 [description] 中明确说明他人将看到的状态.
class EatSwitch extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.pending = false,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// 标识该功能尚未对接接口: 开启后开关正常渲染并在文字后附加 "待接入", 但点击不触发请求且读屏报告不可用.
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final onChanged = pending ? null : this.onChanged;
    final duration = context.motion(EatMotion.select);
    return EatTappable(
      onTap: onChanged == null
          ? null
          : () {
              EatHaptics.selection();
              onChanged(!value);
            },
      button: false,
      toggled: value,
      dimOnPress: false,
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: description == null ? 56 : 64),
        child: Row(
          spacing: EatSpace.s14,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Wrap(
                    spacing: EatSpace.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        label,
                        style: eat.text.subhead.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.ink,
                        ),
                      ),
                      if (pending) const PendingTag(),
                    ],
                  ),
                  if (description case final description?)
                    Text(
                      description,
                      style: eat.text.meta.copyWith(color: c.inkMuted),
                    ),
                ],
              ),
            ),
            _Track(on: value, duration: duration),
          ],
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const new({required this.on, required this.duration});

  final bool on;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    final style = on
        ? SurfaceStyle(
            top: c.inkTop,
            bottom: c.ink,
            inset: const [
              BoxShadow(
                offset: Offset(0, -1),
                color: Color.fromRGBO(0, 0, 0, 0.28),
              ),
            ],
          )
        : SurfaceStyle(
            top: c.handle,
            bottom: c.handle,
            inset: const [
              BoxShadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Color.fromRGBO(35, 28, 24, 0.12),
              ),
            ],
          );
    return Surface(
      style: style,
      duration: duration,
      curve: EatMotion.select.curve,
      child: SizedBox(
        width: 52,
        height: 32,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedAlign(
            duration: duration,
            curve: EatMotion.select.curve,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: c.paper,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Color.fromRGBO(35, 28, 24, 0.28),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
