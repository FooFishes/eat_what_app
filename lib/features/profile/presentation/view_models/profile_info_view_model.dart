import 'package:eat_what_app/features/auth/providers.dart';
import 'package:eat_what_app/features/profile/data/models/update_user_info_request.dart';
import 'package:eat_what_app/features/profile/providers.dart';
import 'package:eat_what_app/features/profile/presentation/view_models/profile_info_state.dart';
import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_info_view_model.g.dart';

@Riverpod(keepAlive: true)
class ProfileInfoViewModel extends _$ProfileInfoViewModel {
  @override
  ProfileInfoState build() {
    Future.microtask(_loadPage);
    return const ProfileInfoState();
  }

  Future<void> _loadPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userInfo = await ref.read(userRepositoryProvider).getUserInfo();
      var provinces = state.provinces;
      var cities = state.cities;

      if (userInfo.hometownProvinceId != null) {
        provinces =
            await ref.read(locationRepositoryProvider).getProvinces();
        cities = await ref
            .read(locationRepositoryProvider)
            .getCities(userInfo.hometownProvinceId!);
      }

      state = state.copyWith(
        isLoading: false,
        userInfo: userInfo,
        provinces: provinces,
        cities: cities,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> reload() => _loadPage();

  Future<void> saveField(UpdateUserInfoRequest request) async {
    await ref.read(userRepositoryProvider).updateUserInfo(request);
    final refreshed = await ref.read(userRepositoryProvider).getUserInfo();
    state = state.copyWith(userInfo: refreshed);
  }

  Future<void> saveHometown({
    required int? provinceId,
    required int? cityId,
    required List<CityResponse> cities,
  }) async {
    await ref.read(userRepositoryProvider).updateUserInfo(
          UpdateUserInfoRequest(
            hometownProvinceId: provinceId,
            hometownCityId: cityId,
          ),
        );
    final refreshed = await ref.read(userRepositoryProvider).getUserInfo();
    state = state.copyWith(userInfo: refreshed, cities: cities);
  }

  Future<String> uploadAvatar(XFile image) async {
    state = state.copyWith(isUploadingAvatar: true);
    try {
      return await ref.read(userRepositoryProvider).uploadAvatar(image);
    } finally {
      state = state.copyWith(isUploadingAvatar: false);
    }
  }

  Future<void> ensureLocationsLoaded() async {
    if (state.isLoadingLocations || state.provinces.isNotEmpty) return;

    state = state.copyWith(isLoadingLocations: true);
    try {
      final provinces =
          await ref.read(locationRepositoryProvider).getProvinces();
      state = state.copyWith(provinces: provinces);

      final provinceId = state.userInfo?.hometownProvinceId;
      if (provinceId != null) {
        final cities =
            await ref.read(locationRepositoryProvider).getCities(provinceId);
        state = state.copyWith(cities: cities);
      }
    } finally {
      state = state.copyWith(isLoadingLocations: false);
    }
  }

  Future<List<CityResponse>> loadCities(int provinceId) {
    return ref.read(locationRepositoryProvider).getCities(provinceId);
  }

  Future<void> checkUsername(String username) {
    return ref.read(authRepositoryProvider).checkUsername(username);
  }
}
