import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required int code,
    @JsonKey(name: 'msg', defaultValue: '') required String message,
    T? data,
    required int timestamp,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  // 私有构造器用于正常生成 getters
  const ApiResponse._();

  bool get isSuccess => code == BizCode.success.code;
  bool get requireReLogin => BizCode.requireReLogin(code);
}
