import 'package:image_picker/image_picker.dart';

import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/error/api_exception_ext.dart';
import 'package:eat_what_app/model/location/city_response.dart';
import 'package:eat_what_app/model/location/province_response.dart';
import 'package:eat_what_app/provider/api_provider.dart';
import 'package:eat_what_app/repository/upload_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_page_controller.g.dart';

const Object _selectedProvinceUnset = Object();
const Object _selectedCityUnset = Object();
const Object _feedbackUnset = Object();

enum UploadPageFeedbackKind { success, warning, error }

class UploadPageFeedback {
  final int id;
  final UploadPageFeedbackKind kind;
  final String content;

  const UploadPageFeedback({
    required this.id,
    required this.kind,
    required this.content,
  });
}

class UploadPageState {
  final bool isLoadingProvinces;
  final bool isLoadingCities;
  final bool isSubmitting;
  final List<ProvinceResponse> provinces;
  final List<CityResponse> cities;
  final ProvinceResponse? selectedProvince;
  final CityResponse? selectedCity;
  final UploadPageFeedback? feedback;

  const UploadPageState({
    this.isLoadingProvinces = false,
    this.isLoadingCities = false,
    this.isSubmitting = false,
    this.provinces = const [],
    this.cities = const [],
    this.selectedProvince,
    this.selectedCity,
    this.feedback,
  });

  UploadPageState copyWith({
    bool? isLoadingProvinces,
    bool? isLoadingCities,
    bool? isSubmitting,
    List<ProvinceResponse>? provinces,
    List<CityResponse>? cities,
    Object? selectedProvince = _selectedProvinceUnset,
    Object? selectedCity = _selectedCityUnset,
    Object? feedback = _feedbackUnset,
  }) {
    return UploadPageState(
      isLoadingProvinces: isLoadingProvinces ?? this.isLoadingProvinces,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      provinces: provinces ?? this.provinces,
      cities: cities ?? this.cities,
      selectedProvince: identical(selectedProvince, _selectedProvinceUnset)
          ? this.selectedProvince
          : selectedProvince as ProvinceResponse?,
      selectedCity: identical(selectedCity, _selectedCityUnset)
          ? this.selectedCity
          : selectedCity as CityResponse?,
      feedback: identical(feedback, _feedbackUnset)
          ? this.feedback
          : feedback as UploadPageFeedback?,
    );
  }
}

@Riverpod(keepAlive: true)
RequestClient uploadRawClient(Ref ref) {
  return RequestClient.raw();
}

@Riverpod(keepAlive: true)
UploadRepository uploadRepository(Ref ref) {
  return UploadRepository(
    api: ref.read(apiProvider),
    rawApi: ref.read(uploadRawClientProvider),
  );
}

@riverpod
class UploadPageController extends _$UploadPageController {
  int _feedbackSeed = 0;
  int _cityRequestSeed = 0;

  @override
  UploadPageState build() {
    Future.microtask(loadProvinces);
    return const UploadPageState();
  }

  Future<void> loadProvinces() async {
    if (state.isLoadingProvinces || state.provinces.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoadingProvinces: true);

    try {
      final provinces = await ref.read(uploadRepositoryProvider).getProvinces();
      state = state.copyWith(isLoadingProvinces: false, provinces: provinces);
    } catch (error) {
      state = state.copyWith(
        isLoadingProvinces: false,
        feedback: _createFeedback(
          UploadPageFeedbackKind.error,
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

    if (province == null) {
      return;
    }

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
      final cities = await ref
          .read(uploadRepositoryProvider)
          .getCities(provinceId);
      if (requestId != _cityRequestSeed) {
        return;
      }
      state = state.copyWith(isLoadingCities: false, cities: cities);
    } catch (error) {
      if (requestId != _cityRequestSeed) {
        return;
      }
      state = state.copyWith(
        isLoadingCities: false,
        feedback: _createFeedback(
          UploadPageFeedbackKind.error,
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
    if (state.isSubmitting) {
      return;
    }

    final trimmedFoodName = foodName.trim();
    if (trimmedFoodName.isEmpty) {
      state = state.copyWith(
        feedback: _createFeedback(UploadPageFeedbackKind.warning, '请输入菜品名称'),
      );
      return;
    }

    if (images.isEmpty) {
      state = state.copyWith(
        feedback: _createFeedback(
          UploadPageFeedbackKind.warning,
          '请至少上传一张菜品照片',
        ),
      );
      return;
    }

    final province = state.selectedProvince;
    if (province == null) {
      state = state.copyWith(
        feedback: _createFeedback(UploadPageFeedbackKind.warning, '请选择省份'),
      );
      return;
    }

    final city = state.selectedCity;
    if (city == null) {
      state = state.copyWith(
        feedback: _createFeedback(UploadPageFeedbackKind.warning, '请选择城市'),
      );
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      await ref
          .read(uploadRepositoryProvider)
          .publishActivityFood(
            foodName: trimmedFoodName,
            description: description,
            provinceId: province.id,
            cityId: city.id,
            images: List<XFile>.unmodifiable(images),
          );

      state = state.copyWith(
        isSubmitting: false,
        feedback: _createFeedback(UploadPageFeedbackKind.success, '发布成功！'),
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedback: _createFeedback(
          UploadPageFeedbackKind.error,
          resolveUserMessage(error),
        ),
      );
    }
  }

  void clearFeedback() {
    if (state.feedback == null) {
      return;
    }
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

  UploadPageFeedback _createFeedback(
    UploadPageFeedbackKind kind,
    String content,
  ) {
    _feedbackSeed++;
    return UploadPageFeedback(id: _feedbackSeed, kind: kind, content: content);
  }
}
