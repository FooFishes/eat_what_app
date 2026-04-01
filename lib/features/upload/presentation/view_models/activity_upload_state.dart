import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_upload_state.freezed.dart';

enum ActivityUploadFeedbackKind { success, warning, error }

@freezed
abstract class ActivityUploadFeedback with _$ActivityUploadFeedback {
  const factory ActivityUploadFeedback({
    required int id,
    required ActivityUploadFeedbackKind kind,
    required String content,
  }) = _ActivityUploadFeedback;
}

@freezed
abstract class ActivityUploadState with _$ActivityUploadState {
  const factory ActivityUploadState({
    @Default(false) bool isLoadingProvinces,
    @Default(false) bool isLoadingCities,
    @Default(false) bool isSubmitting,
    @Default([]) List<ProvinceResponse> provinces,
    @Default([]) List<CityResponse> cities,
    ProvinceResponse? selectedProvince,
    CityResponse? selectedCity,
    ActivityUploadFeedback? feedback,
  }) = _ActivityUploadState;
}
