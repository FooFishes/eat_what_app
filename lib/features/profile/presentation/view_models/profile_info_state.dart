import 'package:eat_what_app/features/profile/data/models/user_info_response.dart';
import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_info_state.freezed.dart';

@freezed
abstract class ProfileInfoState with _$ProfileInfoState {
  const factory ProfileInfoState({
    @Default(true) bool isLoading,
    @Default(false) bool isLoadingLocations,
    @Default(false) bool isUploadingAvatar,
    UserInfoResponse? userInfo,
    @Default([]) List<ProvinceResponse> provinces,
    @Default([]) List<CityResponse> cities,
    Object? error,
  }) = _ProfileInfoState;
}
