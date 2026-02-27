import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 轮播图内置卡片数据模型
class CarouselData {
  final String imagePath; // 支持 http 开头的网图或本地 asset 路径
  final String? title;
  final String? content;

  CarouselData({required this.imagePath, this.title, this.content});
}

class StackedCarousel extends StatefulWidget {
  // 简易用法：仅提供数据源，使用组件内置的好看卡片样式
  final List<CarouselData>? data;

  // 进阶用法：完全自定义的数据集合和卡片构建逻辑
  final List<dynamic>? items;
  final Widget Function(BuildContext context, dynamic item, int index)?
  itemBuilder;

  // 轮播图整体容器的高度
  final double height;
  // 底部选中指示器的颜色
  final Color activeIndicatorColor;
  // 滑动图片的回调
  final ValueChanged<int>? onPageChanged;

  // （仅简易用法生效）内置卡片的圆角
  final double borderRadius;

  // 左右边距
  final double horizontalPadding;

  // 底层堆叠卡片的旋转角度
  final double? stackedCardAngle;

  // 拖拽时的最大旋转角度
  final double? maxDragAngle;

  const StackedCarousel({
    super.key,
    this.data,
    this.items,
    this.itemBuilder,
    this.height = 200,
    this.activeIndicatorColor = const Color(0xFFFCA048),
    this.onPageChanged,
    this.borderRadius = 16.0,
    this.horizontalPadding = 30.0,
    this.stackedCardAngle,
    this.maxDragAngle,
  }) : assert(
         data != null || (items != null && itemBuilder != null),
         '必须提供 data，或者同时提供 items 和 itemBuilder 参数',
       );

  @override
  State<StackedCarousel> createState() => _StackedCarouselState();
}

class _StackedCarouselState extends State<StackedCarousel>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  int get _itemCount => widget.data?.length ?? widget.items!.length;

  // 滑动相关的状态和动画
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;

  // 标记当前动画是否是「飞出」动画（而非弹回）
  bool _isDismissing = false;

  late AnimationController _slideController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _angleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController.addListener(() {
      setState(() {
        if (_slideAnimation != null) {
          _dragOffset = _slideAnimation!.value;
        }
        if (_angleAnimation != null) {
          _dragAngle = _angleAnimation!.value;
        }
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  /// 如果当前有飞出动画在播放，立即跳到终态，释放控制权给新手势
  void _completeCurrentDismissal() {
    _slideController.stop();
    setState(() {
      _currentIndex = (_currentIndex + 1) % _itemCount;
      _dragOffset = Offset.zero;
      _dragAngle = 0.0;
      _isDismissing = false;
    });
    if (widget.onPageChanged != null) {
      widget.onPageChanged!(_currentIndex);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_slideController.isAnimating) {
      if (_isDismissing) {
        // 飞出动画正在播放 → 立即完成当前卡片的切换
        _completeCurrentDismissal();
      } else {
        // 弹回动画正在播放 → 直接中断，从当前位置开始新的拖拽
        _slideController.stop();
      }
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // 禁用垂直位移，仅在横向上进行滑动
      double newDx = _dragOffset.dx + details.delta.dx;

      _dragOffset = Offset(newDx, 0.0);
      // 旋转角度与横向位移成比例，减小旋转幅度
      final maxAngle = widget.maxDragAngle ?? (pi / 36);
      _dragAngle =
          _dragOffset.dx / MediaQuery.of(context).size.width * maxAngle;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // 滑动距离超过屏幕 1/3，或者滑动速度快过 800px/s 时，触发飞出屏幕（下一张）的逻辑
    final screenWidth = MediaQuery.of(context).size.width;
    if (_dragOffset.dx.abs() > screenWidth * 0.3 ||
        details.velocity.pixelsPerSecond.dx.abs() > 800) {
      final sign = _dragOffset.dx.sign;
      _slideAnimation =
          Tween<Offset>(
            begin: _dragOffset,
            end: Offset(sign * screenWidth, 0.0), // 飞出屏幕外
          ).animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
          );

      _angleAnimation =
          Tween<double>(
            begin: _dragAngle,
            // 飞出时的追加角度降低，避免过度旋转
            end: _dragAngle + (sign * pi / 16),
          ).animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
          );

      _isDismissing = true;
      _slideController.forward(from: 0.0).then((_) {
        // 只有在动画自然结束时才处理（被中断的情况由 _completeCurrentDismissal 处理）
        if (!_isDismissing) return;
        // 动画结束（彻底飞出视野之后），重置位置、角度为空并真正切换到下一张
        setState(() {
          _currentIndex = (_currentIndex + 1) % _itemCount;
          _dragOffset = Offset.zero;
          _dragAngle = 0.0;
          _isDismissing = false;
        });
        if (widget.onPageChanged != null) {
          widget.onPageChanged!(_currentIndex);
        }
      });
    } else {
      // 拖拽距离不够长，松手时弹回原点（撤销滑动操作）
      _slideAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutBack,
            ),
          );

      _angleAnimation = Tween<double>(begin: _dragAngle, end: 0.0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
      );

      _isDismissing = false;
      _slideController.forward(from: 0.0);
    }
  }

  /// 构建默认样式的卡片视图（图片+底部半透明黑底图文层）
  Widget _buildDefaultCard(BuildContext context, CarouselData data) {
    bool isNetwork = data.imagePath.startsWith('http');
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ============ 1. 图片底层 ============
            isNetwork
                ? CachedNetworkImage(
                    imageUrl: data.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Image.asset(data.imagePath, fit: BoxFit.cover),

            // ============ 2. 文字蒙层 ============
            // 只有当有标题或内容时才覆盖底部黑色透明渐变以凸显文字
            if (data.title != null || data.content != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  // 从下往上由深黑色透明向完全透明过度
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.title != null)
                        Text(
                          data.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (data.content != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.content!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) return const SizedBox.shrink();

    // 控制同时最多展示的卡片层数（底层露出的数量）
    final visibleCount = min(3, _itemCount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      // 增加上部间距避免因为旋转导致卡片头部被裁剪
      children: [
        const SizedBox(height: 10),
        Padding(
          // 将左右 padding 加大，才能留出缝隙给下面的牌漏出它的左右边界
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: GestureDetector(
            // 手势检测器放在最外层，确保即使顶牌飞出屏幕，轮播区域也始终可以接收新的拖拽手势
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: widget.height,
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(visibleCount, (i) {
                      int reversedIndex = visibleCount - 1 - i;
                      int dataIndex =
                          (_currentIndex + reversedIndex) % _itemCount;

                      Widget cardChild = widget.data != null
                          ? _buildDefaultCard(context, widget.data![dataIndex])
                          : widget.itemBuilder!(
                              context,
                              widget.items![dataIndex],
                              dataIndex,
                            );

                      if (reversedIndex == 0) {
                        // 顶牌在被滑出的过程中，我们可以让它逐渐变透明，防止它飞出时遮挡 AppBar 或 BottomNavigationBar
                        final screenWidth = MediaQuery.of(context).size.width;

                        // 减缓透明度消失的速度：让拖动距离达到整个屏幕宽度时才完全透明
                        // 这样在刚开始滑以及飞出的前半段，它还能保持一定的可见度
                        double opacityProgress =
                            (_dragOffset.dx.abs() / screenWidth).clamp(
                              0.0,
                              1.0,
                            );
                        double topOpacity = (1.0 - opacityProgress).clamp(
                          0.0,
                          1.0,
                        );

                        return Positioned.fill(
                          child: Opacity(
                            opacity: topOpacity,
                            child: Transform.translate(
                              offset: _dragOffset,
                              child: Transform.rotate(
                                angle: _dragAngle,
                                alignment: Alignment.bottomCenter,
                                child: cardChild,
                              ),
                            ),
                          ),
                        );
                      } else {
                        // 这里是核心：利用 _slideController 的进度来插值动画
                        // _slideController.value 范围 0.0 -> 1.0 (在手指按住拖动时是 0，松手飞出时或弹回时才是动画运作)
                        // 然而拖动时 _dragOffset 也是在变化的，所以我们需要一个综合进度 `progress`

                        final screenWidth = MediaQuery.of(context).size.width;
                        // 1. 拖拽产生的纯物理进度 (0.0 ~ 1.0)
                        double dragProgress =
                            (_dragOffset.dx.abs() / (screenWidth * 0.5)).clamp(
                              0.0,
                              1.0,
                            );

                        // 2. 只有当确实在向下一张切换（飞出屏幕的动画）时，或者拖动得很远时，底下的卡牌才逐渐变成顶牌
                        // 弹回原位的动画过程中，进度会跟着 _dragOffset.dx 一起回退到 0
                        double animProgress = Curves.easeOut.transform(
                          dragProgress,
                        );

                        final baseAngle = widget.stackedCardAngle ?? (pi / 45);

                        // --- 前一个状态 (当前 reversedIndex) ---
                        double scale1 = 1.0;
                        double dy1 = reversedIndex * 2.0;
                        double angle1 = reversedIndex == 1
                            ? -baseAngle
                            : baseAngle;

                        // --- 目标状态 (上一层 reversedIndex - 1) ---
                        double scale2 = 1.0; // Added missing scale2
                        double dy2 = (reversedIndex - 1) * 2.0;
                        // 如果上一层是顶层(0)，角度应该完全回正到 0
                        double angle2 = (reversedIndex - 1) == 0
                            ? 0.0
                            : ((reversedIndex - 1) == 1
                                  ? -baseAngle
                                  : baseAngle);

                        // --- 实时插值 ---
                        double currentScale =
                            lerpDouble(scale1, scale2, animProgress) ?? scale1;
                        double currentDy =
                            lerpDouble(dy1, dy2, animProgress) ?? dy1;
                        double currentAngle =
                            lerpDouble(angle1, angle2, animProgress) ?? angle1;

                        // --- 对于第三张卡片的渐变出现 ---
                        // 如果它是当前看得到的最后一张卡片，我们在滑动过程中让它从透明渐渐变成不透明
                        // 从而避免上一张卡片飞走后，最底层的牌突然出现的生硬感
                        double currentOpacity = 1.0;
                        if (reversedIndex == visibleCount - 1) {
                          currentOpacity = Curves.easeIn.transform(
                            animProgress,
                          );
                        }

                        return Positioned.fill(
                          child: Opacity(
                            opacity: currentOpacity,
                            child: Transform.translate(
                              offset: Offset(0, currentDy),
                              child: Transform.scale(
                                scale: currentScale,
                                alignment: Alignment.bottomCenter,
                                child: Transform.rotate(
                                  angle: currentAngle,
                                  alignment: Alignment.bottomCenter,
                                  child: cardChild,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 24), // 底部留出空间展示超出边缘的部分

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_itemCount, (index) {
            bool isActive = _currentIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: isActive ? 8.0 : 6.0,
              height: isActive ? 8.0 : 6.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isActive
                    ? null
                    : Border.all(
                        color: widget.activeIndicatorColor.withValues(
                          alpha: 0.5,
                        ),
                        width: 1.5,
                      ),
                color: isActive
                    ? widget.activeIndicatorColor
                    : Colors.transparent,
              ),
            );
          }),
        ),
      ],
    );
  }
}
