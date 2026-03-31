import 'package:flutter/material.dart';

class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 320);
  static const _curve = Curves.easeInOutCubic;

  late final AnimationController _controller;
  late final Animation<double> _inOpacity;
  late final Animation<double> _outOpacity;

  int _previousIndex = 0;
  bool _movingForward = true;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1,
    );
    _inOpacity = CurvedAnimation(parent: _controller, curve: _curve);
    _outOpacity = Tween<double>(
      begin: 1,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: _curve));
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _movingForward = widget.currentIndex > oldWidget.currentIndex;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAnimating = _controller.isAnimating;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: List<Widget>.generate(widget.children.length, (index) {
            final isCurrent = index == widget.currentIndex;
            final isPrevious = index == _previousIndex;
            final shouldPaint = isCurrent || (isAnimating && isPrevious);

            if (!shouldPaint) {
              return Offstage(
                offstage: true,
                child: TickerMode(
                  enabled: false,
                  child: widget.children[index],
                ),
              );
            }

            final opacity = isCurrent ? _inOpacity : _outOpacity;
            final offset = isCurrent
                ? Tween<Offset>(
                    begin: Offset(_movingForward ? 1 : -1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: _controller, curve: _curve))
                : Tween<Offset>(
                    begin: Offset.zero,
                    end: Offset(_movingForward ? -1 : 1, 0),
                  ).animate(
                    CurvedAnimation(parent: _controller, curve: _curve),
                  );

            return Offstage(
              offstage: false,
              child: TickerMode(
                enabled: isCurrent,
                child: IgnorePointer(
                  ignoring: !isCurrent,
                  child: SlideTransition(
                    position: offset,
                    child: FadeTransition(
                      opacity: opacity,
                      child: widget.children[index],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
