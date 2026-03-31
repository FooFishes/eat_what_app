import 'package:eat_what_app/app/shell/app_shell_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_shell_view_model.g.dart';

@Riverpod(keepAlive: true)
class AppShellViewModel extends _$AppShellViewModel {
  @override
  AppShellState build() {
    return const AppShellState(isNavigationBarVisible: true);
  }

  void hideNavigationBar() {
    state = state.copyWith(isNavigationBarVisible: false);
  }

  void showNavigationBar() {
    state = state.copyWith(isNavigationBarVisible: true);
  }

  void toggleVisibility() {
    state = state.copyWith(
      isNavigationBarVisible: !state.isNavigationBarVisible,
    );
  }
}
