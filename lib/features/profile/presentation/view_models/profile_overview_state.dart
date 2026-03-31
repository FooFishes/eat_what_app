import 'package:eat_what_app/features/profile/data/models/user_info_response.dart';
import 'package:eat_what_app/features/profile/data/models/user_profile_stats_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_overview_state.freezed.dart';

@freezed
abstract class ProfileOverviewState with _$ProfileOverviewState {
  const factory ProfileOverviewState({
    @Default(true) bool isLoading,
    UserInfoResponse? userInfo,
    UserProfileStatsResponse? stats,
    Object? error,
  }) = _ProfileOverviewState;
}
