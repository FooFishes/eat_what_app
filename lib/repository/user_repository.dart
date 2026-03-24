import 'package:dio/dio.dart';
import 'package:eat_what_app/core/api/api_parser.dart';
import 'package:eat_what_app/core/api/model/api_response.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/history/browse_history_item_response.dart';
import 'package:eat_what_app/model/upload/presign_upload_dto.dart';
import 'package:eat_what_app/model/user/update_user_info_request.dart';
import 'package:eat_what_app/model/user/user_info_response.dart';
import 'package:eat_what_app/model/user/user_profile_stats_response.dart';
import 'package:image_picker/image_picker.dart';

class UserRepository {
  final RequestClient _api;
  final RequestClient _rawApi;

  const UserRepository({
    required RequestClient api,
    required RequestClient rawApi,
  }) : _api = api,
       _rawApi = rawApi;

  Future<UserInfoResponse> getUserInfo() async {
    final result = await _api.get<UserInfoResponse>(
      Urls.userInfo,
      parser: (data) => ApiParser.parseObject(data, UserInfoResponse.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '用户信息为空');
    }

    return result;
  }

  Future<UserProfileStatsResponse> getUserProfileStats(int userId) async {
    final result = await _api.get<UserProfileStatsResponse>(
      Urls.userProfileStats,
      queryParameters: {'userId': userId},
      parser: (data) =>
          ApiParser.parseObject(data, UserProfileStatsResponse.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '用户统计信息为空');
    }

    return result;
  }

  Future<void> updateUserInfo(UpdateUserInfoRequest request) async {
    await _api.put<Object?>(
      Urls.updateUserInfo,
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<PaginatedData<BrowseHistoryItemResponse>> getBrowseHistory({
    required String targetType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _api.get<PaginatedData<BrowseHistoryItemResponse>>(
      Urls.browseHistory,
      queryParameters: {
        'targetType': targetType,
        'page': page,
        'pageSize': pageSize,
      },
      parser: (data) => ApiParser.parsePage(
        data,
        fromJson: BrowseHistoryItemResponse.fromJson,
      ),
    );

    if (result == null) {
      throw const ParseException(message: '浏览历史为空');
    }

    return result;
  }

  Future<String> uploadAvatar(XFile file) async {
    final contentType = _resolveMimeType(file.name);
    final request = await PresignUploadRequest.fromXFile(
      file,
      contentType: contentType,
      biz: 'avatar',
    );

    final presign = await _api.post<PresignUploadResponse>(
      Urls.uploadPresign,
      data: request.toJson(),
      parser: (data) =>
          ApiParser.parseObject(data, PresignUploadResponse.fromJson),
    );

    if (presign == null) {
      throw const ParseException(message: '头像上传预签名为空');
    }

    await _rawApi.putRaw(
      presign.putUrl,
      data: await file.readAsBytes(),
      options: Options(headers: {'Content-Type': contentType}),
    );

    return presign.key;
  }

  String _resolveMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
  }
}
