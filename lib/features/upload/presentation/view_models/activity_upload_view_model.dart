import 'package:eat_what_app/core/error/api_exception_ext.dart';
import 'package:eat_what_app/features/upload/presentation/view_models/activity_upload_state.dart';
import 'package:eat_what_app/features/upload/providers.dart';
import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';
import 'package:eat_what_app/shared/location/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'activity_upload_view_model.g.dart';

@riverpod
class ActivityUploadViewModel extends _$ActivityUploadViewModel {
  int _feedbackSeed = 0;
  int _cityRequestSeed = 0;

  @override
  ActivityUploadState build() {
    Future.microtask(loadProvinces);
    return const ActivityUploadState();
  }

  Future<void> loadProvinces() async {
    if (state.isLoadingProvinces || state.provinces.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoadingProvinces: true);

    try {
      final provinces =
          await ref.read(locationRepositoryProvider).getProvinces();
      state = state.copyWith(isLoadingProvinces: false, provinces: provinces);
    } catch (error) {
      state = state.copyWith(
        isLoadingProvinces: false,
        feedback: _createFeedback(
          ActivityUploadFeedbackKind.error,
          resolveUserMessage(error),
        ),
      );
    }
  }

  Future<void> selectProvince(ProvinceResponse? province) async {
    _cityRequestSeed++;
    state = state.copyWith(
      selectedProvince: province,
      selectedCity: null,
      cities: const [],
      isLoadingCities: false,
    );

    if (province == null) return;
    await loadCities(province.id);
  }

  Future<void> loadCities(int provinceId) async {
    final requestId = ++_cityRequestSeed;
    state = state.copyWith(
      isLoadingCities: true,
      cities: const [],
      selectedCity: null,
    );

    try {
      final cities =
          await ref.read(locationRepositoryProvider).getCities(provinceId);
      if (requestId != _cityRequestSeed) return;
      state = state.copyWith(isLoadingCities: false, cities: cities);
    } catch (error) {
      if (requestId != _cityRequestSeed) return;
      state = state.copyWith(
        isLoadingCities: false,
        feedback: _createFeedback(
          ActivityUploadFeedbackKind.error,
          resolveUserMessage(error),
        ),
      );
    }
  }

  void selectCity(CityResponse? city) {
    state = state.copyWith(selectedCity: city);
  }

  Future<void> submit({
    required String foodName,
    required String? description,
    required List<XFile> images,
  }) async {
    if (state.isSubmitting) return;

    final trimmedFoodName = foodName.trim();
    if (trimmedFoodName.isEmpty) {
      state = state.copyWith(
        feedback: _createFeedback(ActivityUploadFeedbackKind.warning, '请输入菜品名称'),
      );
      return;
    }

    if (images.isEmpty) {
      state = state.copyWith(
        feedback: _createFeedback(
            ActivityUploadFeedbackKind.warning, '请至少上传一张菜品照片'),
      );
      return;
    }

    final province = state.selectedProvince;
    if (province == null) {
      state = state.copyWith(
        feedback: _createFeedback(ActivityUploadFeedbackKind.warning, '请选择省份'),
      );
      return;
    }

    final city = state.selectedCity;
    if (city == null) {
      state = state.copyWith(
        feedback: _createFeedback(ActivityUploadFeedbackKind.warning, '请选择城市'),
      );
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      await ref.read(uploadRepositoryProvider).publishActivityFood(
            foodName: trimmedFoodName,
            description: description,
            provinceId: province.id,
            cityId: city.id,
            images: List<XFile>.unmodifiable(images),
          );

      state = state.copyWith(
        isSubmitting: false,
        feedback: _createFeedback(ActivityUploadFeedbackKind.success, '发布成功！'),
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedback: _createFeedback(
          ActivityUploadFeedbackKind.error,
          resolveUserMessage(error),
        ),
      );
    }
  }

  void clearFeedback() {
    if (state.feedback == null) return;
    state = state.copyWith(feedback: null);
  }

  void resetSelections() {
    _cityRequestSeed++;
    state = state.copyWith(
      selectedProvince: null,
      selectedCity: null,
      cities: const [],
      isLoadingCities: false,
    );
  }

  ActivityUploadFeedback _createFeedback(
    ActivityUploadFeedbackKind kind,
    String content,
  ) {
    _feedbackSeed++;
    return ActivityUploadFeedback(id: _feedbackSeed, kind: kind, content: content);
  }
}
