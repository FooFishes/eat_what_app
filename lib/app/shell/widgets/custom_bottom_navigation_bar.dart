import 'package:flutter/material.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final List<Widget> items;
  final int currentIndex;
  final double height;
  final EdgeInsetsGeometry padding;

  const new({
    super.key,
    required this.items,
    required this.currentIndex,
    this.height = 100,
    this.padding = const EdgeInsets.fromLTRB(15, 8, 15, 6),
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final double safeBottom = MediaQuery.paddingOf(context).bottom
        .clamp(0.0, 12.0);

    return Container(
      width: double.infinity,
      color: const Color(0xFFF3EDD1),
      padding: .only(bottom: safeBottom),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int itemCount = items.length;
              final int safeIndex = currentIndex < 0
                  ? 0
                  : (currentIndex >= itemCount ? itemCount - 1 : currentIndex);
              final double itemWidth = constraints.maxWidth / itemCount;
              const double highlightWidth = 65.0;
              const double highlightHeight = 65.0;
              final double itemCenterX =
                  (itemWidth * safeIndex) + (itemWidth / 2);
              final double left = itemCenterX - (highlightWidth / 2);

              return Stack(
                children: <Widget>[
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    left: left,
                    top: 0,
                    width: highlightWidth,
                    height: highlightHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: .circular(16),
                      ),
                    ),
                  ),
                  Row(
                    children: items
                        .map(
                          (Widget item) => Expanded(
                            child: Align(alignment: .topCenter, child: item),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
