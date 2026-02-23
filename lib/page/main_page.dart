import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eat_what_app/provider/navigation_bar_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eat_what_app/widget/custom_bottom_navigation_bar.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class MainPage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  static const List<_BottomTabItemData> _tabs = <_BottomTabItemData>[
    _BottomTabItemData(label: '首页', iconAsset: 'assets/icons/home.svg'),
    _BottomTabItemData(label: '地图', iconAsset: 'assets/icons/map.svg'),
    _BottomTabItemData(label: '上传', iconAsset: 'assets/icons/upload.svg'),
    _BottomTabItemData(label: '餐厅', iconAsset: 'assets/icons/restaurant.svg'),
    _BottomTabItemData(label: '我的', iconAsset: 'assets/icons/profile.svg'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isNavigationBarVisible = ref.watch(
      navigationBarProvider.select((s) => s.isNavigationBarVisible),
    );
    final int currentIndex = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            right: 0,
            bottom: 0,
            left: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: isNavigationBarVisible ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                opacity: isNavigationBarVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: CustomBottomNavigationBar(
                  currentIndex: currentIndex,
                  items: List<Widget>.generate(_tabs.length, (index) {
                    return _buildItem(
                      ref: ref,
                      item: _tabs[index],
                      index: index,
                      isSelected: currentIndex == index,
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required WidgetRef ref,
    required _BottomTabItemData item,
    required int index,
    required bool isSelected,
    double size = 32.0,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        height: 85,
        width: 65,
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 65,
              height: 65,
              child: Center(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  offset: isSelected ? Offset.zero : const Offset(0, 0.04),
                  child: AnimatedScale(
                    scale: isSelected ? 1.03 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: SvgPicture.asset(
                        item.iconAsset,
                        key: ValueKey<String>(
                          isSelected
                              ? '${item.label}_selected'
                              : '${item.label}_normal',
                        ),
                        width: size,
                        height: size,
                        colorFilter: ColorFilter.mode(
                          isSelected ? Colors.white : Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withValues(alpha: 0.66),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    );
  }
}

class _BottomTabItemData {
  final String label;
  final String iconAsset;

  const _BottomTabItemData({required this.label, required this.iconAsset});
}
