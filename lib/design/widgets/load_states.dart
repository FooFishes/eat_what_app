import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_layout.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:flutter/widgets.dart';

/// 加载中的占位：`mist` 色块按内容的形状摆（舞台、盘子、方块、列表行），不用转圈。
///
/// 一组占位外面包一层 [LoadingArea]，读屏只报一次「加载中」。
class Skeleton extends StatelessWidget {
  /// 方块、缩略图这类圆角矩形。
  const new({
    super.key,
    this.width,
    required this.height,
    this.radius = EatRadius.thumb,
  }) : circle = false;

  /// 盘子、头像。
  const new circle({super.key, required double size})
    : width = size,
      height = size,
      radius = Radius.zero,
      circle = true;

  /// 一行字：高度取字号，四角稍圆。
  const new line({super.key, this.width, double fontSize = 15})
    : height = fontSize,
      radius = const Radius.circular(4),
      circle = false;

  /// 不传时撑满父组件给的宽度。
  final double? width;
  final double height;
  final Radius radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.eat.colors.mist,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.all(radius),
      ),
    ),
  );
}

/// 一组 [Skeleton] 的外壳：读屏报一次「加载中」，里面的色块都不读。
class LoadingArea extends StatelessWidget {
  const new({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '加载中',
    liveRegion: true,
    child: ExcludeSemantics(child: child),
  );
}

/// 空状态和其他整块的说明：圆底图标、一句标题、一两句话，可选一个按钮。
///
/// 空状态要说清楚下一步做什么，如「没找到「螺蛳粉」」配「换个词试试……」和「新建一家店」。
class EmptyState extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final EatIcons icon;
  final String title;
  final String? message;

  /// 一般是 48px 高的 `EatButton.outline` 或 `EatButton.mist`。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: EatSpace.s10,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
          child: Center(child: EatIcon(icon, size: 28, color: c.inkMuted)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: eat.text.sectionTitle.copyWith(color: c.ink),
            ),
          ),
        ),
        if (message case final message?)
          Text(
            message,
            textAlign: TextAlign.center,
            style: eat.text.body.copyWith(
              fontSize: 14,
              height: 22 / 14,
              color: c.inkMuted,
            ),
          ),
        if (action case final action?)
          Padding(padding: const EdgeInsets.only(top: 8), child: action),
      ],
    );
  }
}

/// 没有旧数据可显示、请求又失败时的样子：「没加载出来」加「再试一次」。
///
/// 有旧数据时不用它：保留旧内容，只给一句不打断操作的提示。
class FailureState extends StatelessWidget {
  const new({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;

  /// 补一句原因，如「网络不太好」。
  final String? message;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: EatIcons.wifiOff,
    title: '没加载出来',
    message: message,
    action: EatButton.mist(
      '再试一次',
      icon: EatIcons.shuffle,
      height: 48,
      onPressed: onRetry,
    ),
  );
}
