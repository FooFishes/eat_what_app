import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:flutter/widgets.dart';

/// 加载占位组件, 使用 `mist` 色块按目标内容形状排列 (如舞台, 盘子, 方块和列表行), 不使用进度圈.
///
/// 一组占位外需包裹 [LoadingArea], 使读屏仅报告一次 "加载中".
class Skeleton extends StatelessWidget {
  /// 创建圆角矩形占位, 用于方块和缩略图.
  const new({
    super.key,
    this.width,
    required this.height,
    this.radius = EatRadius.thumb,
  }) : circle = false;

  /// 创建圆形占位, 用于盘子和头像.
  const new circle({super.key, required double size})
    : width = size,
      height = size,
      radius = Radius.zero,
      circle = true;

  /// 创建单行文字占位, 高度等于字号且四角略带圆角.
  const new line({super.key, this.width, double fontSize = 15})
    : height = fontSize,
      radius = const Radius.circular(4),
      circle = false;

  /// 占位宽度, 未传入时撑满父组件提供的可用宽度.
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

/// 一组 [Skeleton] 的语义外壳, 使读屏仅报告一次 "加载中" 而忽略内部色块.
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

/// 空状态及整块说明组件, 依次包含圆底图标, 标题, 说明正文和可选按钮.
///
/// 空状态须明确提示下一步操作; 例如搜索无结果时, 正文提示更换关键词并将按钮设为 "新建一家店".
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

  /// 可选的操作按钮, 通常为 48px 高的 `EatButton.outline` 或 `EatButton.mist`.
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
              style: eat.text.heading.copyWith(color: c.ink),
            ),
          ),
        ),
        if (message case final message?)
          Text(
            message,
            textAlign: TextAlign.center,
            style: eat.text.body.copyWith(color: c.inkMuted),
          ),
        if (action case final action?)
          Padding(padding: const EdgeInsets.only(top: 8), child: action),
      ],
    );
  }
}

/// 无旧数据且请求失败时的兜底状态, 展示 "加载失败" 文案与 "重试" 按钮.
///
/// 若页面已有旧数据则不应使用本组件, 而应保留旧内容并给出不打断操作的轻量提示.
class FailureState extends StatelessWidget {
  const new({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;

  /// 失败原因描述, 如 "网络连接失败".
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

/// 舞台区域的加载占位, 右侧为盘子形状, 左下为多行文字形状, 使用舞台次按钮色绘制并随舞台色同步变化.
///
/// 仅能放置于 `StageScaffold` 的舞台内容中, 文字形状底部已自动预留被抽屉遮挡的高度.
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

/// 两列菜品方块的加载占位, 间距与 `SliverTileGrid` 保持一致.
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

/// 置于列表末尾的分页加载触发器, 进入预加载范围时回调一次 [onVisible] 以加载下一页.
///
/// - [generation] 通常传入当前列表条数, 加载后条数变化时会触发下一轮检查.
/// - 已无更多数据时不应放置本组件.
/// - 当 [failed] 为 true 时停止自动加载并展示 "加载失败" 与 "重试", 避免失败后死循环重试.
/// - 加载期间显示一行 "正在加载", 以免列表末尾留空时无法区分加载中与已到底部.
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
        : Center(
            child: Text(
              '正在加载',
              style: context.eat.text.caption.copyWith(
                color: context.eat.colors.inkMuted,
              ),
            ),
          ),
  );
}

/// 列表行的加载占位, 左侧为缩略图形状, 右侧为两行文字形状.
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
