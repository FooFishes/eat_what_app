import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_bar_provider.g.dart';

/// 导航栏状态管理
/// 用于管理自定义导航栏的索引值和是否显示
@Riverpod(keepAlive: true)
class NavigationBar extends _$NavigationBar {
  @override
  NavigationBarState build() {
    return const NavigationBarState(isNavigationBarVisible: true);
  }

  Future<void> hideNavigationBar() async {
    state = state.copyWith(isNavigationBarVisible: false);
  }

  Future<void> showNavigationBar() async {
    state = state.copyWith(isNavigationBarVisible: true);
  }

  Future<void> toggleVisibility() async {
    state = state.copyWith(
      isNavigationBarVisible: !state.isNavigationBarVisible,
    );
  }
}

class NavigationBarState {
  final bool isNavigationBarVisible;

  const NavigationBarState({required this.isNavigationBarVisible});

  NavigationBarState copyWith({bool? isNavigationBarVisible}) {
    return NavigationBarState(
      isNavigationBarVisible:
          isNavigationBarVisible ?? this.isNavigationBarVisible,
    );
  }
}
