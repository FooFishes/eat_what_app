import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_shell_state.freezed.dart';

@freezed
abstract class AppShellState with _$AppShellState {
  const factory AppShellState({
    @Default(true) bool isNavigationBarVisible,
  }) = _AppShellState;
}
