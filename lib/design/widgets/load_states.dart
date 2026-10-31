import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
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

/// 没有旧数据可显示、请求又失败时的样子：「加载失败」加「重试」。
///
/// 有旧数据时不用它：保留旧内容，只给一句不打断操作的提示。
class FailureState extends StatelessWidget {
  const new({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;

  /// 补一句原因，如「网络连接失败」。
  final String? message;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: EatIcons.wifiOff,
    title: '加载失败',
    message: message,
    action: EatButton.mist(
      '重试',
      icon: EatIcons.shuffle,
      height: 48,
      onPressed: onRetry,
    ),
  );
}

/// 舞台上的加载占位：右边一个盘子、左下几行字的形状，用舞台的次按钮色画，跟着舞台色走。
///
/// 只能放在舞台里（`StageScaffold` 的舞台内容）；字的形状离底部留出被抽屉压住的 32px。
class StagePlaceholder extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final color = StageTheme.of(context).ghost;
    final scale = EatLayout.of(context).stageScale;
    Widget block(double width, double height, {bool circle = false}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle
                ? null
                : const BorderRadius.all(Radius.circular(8)),
          ),
        );
    final plate = EatSize.plate * scale;
    return LoadingArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -plate * 0.28,
              top: (constraints.maxHeight - plate) / 2,
              child: block(plate, plate, circle: true),
            ),
            Positioned(
              left: EatSpace.s20,
              bottom: EatSize.sheetOverlap + EatSpace.s24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: EatSpace.s10,
                children: [
                  block(170, 40),
                  block(110, 40),
                  const SizedBox(height: EatSpace.s14),
                  block(96, 52),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 两列菜品方块的加载占位，排法和 `DishTile` 的网格一样。
class TileGridPlaceholder extends StatelessWidget {
  const new({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    Widget tile() => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s8,
      children: [
        Skeleton(height: 150, radius: EatRadius.tile),
        Skeleton.line(width: 90),
        Skeleton.line(width: 60, fontSize: 13),
      ],
    );
    return LoadingArea(
      child: Column(
        spacing: 18,
        children: [
          for (var i = 0; i < count; i += 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: EatSpace.s14,
              children: [
                Expanded(child: tile()),
                Expanded(child: i + 1 < count ? tile() : const SizedBox()),
              ],
            ),
        ],
      ),
    );
  }
}

/// 放在列表最后：滚到快看见它时（进了列表的预加载范围）调一次 [onVisible] 加载下一页。
///
/// [generation] 一般传当前条数：加载回来条数变了，就再触发一次；没有更多时不要放它。
/// [failed] 时不自动加载，换成「加载失败」和「重试」，免得一直重试。
class LoadMoreTrigger extends StatefulWidget {
  const new({
    super.key,
    required this.generation,
    required this.onVisible,
    this.failed = false,
  });

  final int generation;
  final VoidCallback onVisible;
  final bool failed;

  @override
  State<LoadMoreTrigger> createState() => _LoadMoreTriggerState();
}

class _LoadMoreTriggerState extends State<LoadMoreTrigger> {
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(LoadMoreTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation ||
        oldWidget.failed && !widget.failed) {
      _schedule();
    }
  }

  void _schedule() {
    if (widget.failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.failed) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: EatSpace.s16),
    child: widget.failed
        ? Center(
            child: EatButton.mist(
              '加载失败，重试',
              icon: EatIcons.wifiOff,
              height: 40,
              onPressed: widget.onVisible,
            ),
          )
        : const SizedBox(height: 20),
  );
}

/// 列表行的加载占位：左边缩略图，右边两行字。
class RowListPlaceholder extends StatelessWidget {
  const new({super.key, this.count = 4, this.thumbSize = EatSize.thumb});

  final int count;
  final double thumbSize;

  @override
  Widget build(BuildContext context) => LoadingArea(
    child: Column(
      spacing: 18,
      children: [
        for (var i = 0; i < count; i++)
          Row(
            spacing: EatSpace.s14,
            children: [
              Skeleton(
                width: thumbSize,
                height: thumbSize,
                radius: thumbSize >= EatSize.thumbLg
                    ? EatRadius.thumbLg
                    : EatRadius.thumb,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: EatSpace.s8,
                  children: [
                    Skeleton.line(width: 140, fontSize: 16),
                    Skeleton.line(width: 90, fontSize: 13),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
