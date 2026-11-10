import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/sessions/sessions_api.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_api.g.dart';

/// UserApi 调用的接口路径, 相对于业务接口地址.
abstract final class UserEndpoints {
  static const info = '/user/info';
  static const userInfo = '/user/userInfo';
  static const updateInfo = '/user/updateInfo';
  static const follow = '/user/follow';
  static const unfollow = '/user/unfollow';
  static const followers = '/user/followers';
  static const followings = '/user/followings';
  static const changePrivacy = '/user/changePrivacy';
  static String block(int userId) => '/user/blocks/$userId';
  static const blocks = '/user/blocks';
  static const recommendationSettings = '/user/recommendation-settings';
  static String mobileCommandCodes(String commandId) =>
      '/user/mobile/commands/$commandId/codes';
  static String mobileCommandCommit(String commandId) =>
      '/user/mobile/commands/$commandId/commit';
  static String mobileCommandResume(String commandId) =>
      '/user/mobile/commands/$commandId/resume';
  static const mobileCommands = '/user/mobile/commands';
}

/// 接口分组 User: 当前用户, 资料, 关注, 隐私, 屏蔽, 个性化推荐和换绑手机.
class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  Future<UserInfoDto> info() async =>
      decodeJson(await _client.get(UserEndpoints.info), UserInfoDto.fromJson);

  Future<UserProfileDto> profile(
    int userId, {
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.get(
      UserEndpoints.userInfo,
      query: {'userId': userId},
      cancelToken: cancelToken,
    ),
    UserProfileDto.fromJson,
  );

  /// 更新昵称, 头像和签名. [avatar] 是上传后得到的存储 key, 为 null 时不修改头像.
  Future<void> updateInfo({
    required String displayName,
    required String signature,
    String? avatar,
  }) => _client.put(
    UserEndpoints.updateInfo,
    body: {
      'displayName': displayName,
      'signature': signature,
      'avatar': ?avatar,
    },
  );

  Future<void> follow(int userId) =>
      _client.post(UserEndpoints.follow, query: {'userId': userId});

  Future<void> unfollow(int userId) =>
      _client.post(UserEndpoints.unfollow, query: {'userId': userId});

  /// [userId] 的粉丝. 对方不公开粉丝列表时失败, 业务码为 `BizCodes.notSupported`.
  Future<Paged<FansDto>> followers(
    int userId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      UserEndpoints.followers,
      query: {'userId': userId, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FansDto.fromJson,
  );

  /// [userId] 关注的人. 对方不公开关注列表时失败, 业务码为 `BizCodes.notSupported`.
  Future<Paged<FansDto>> followings(
    int userId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      UserEndpoints.followings,
      query: {'userId': userId, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FansDto.fromJson,
  );

  /// 是否公开关注列表 ([following]) 和粉丝列表 ([follower]).
  Future<void> changePrivacy({
    required bool following,
    required bool follower,
  }) => _client.post(
    UserEndpoints.changePrivacy,
    body: {'following': following, 'follower': follower},
  );

  Future<Paged<BlockedUserDto>> blocks({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      UserEndpoints.blocks,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    BlockedUserDto.fromJson,
  );

  /// 当前用户是否屏蔽了 [userId].
  Future<bool> blocked(int userId, {CancelToken? cancelToken}) async =>
      _blocked(
        await _client.get(
          UserEndpoints.block(userId),
          cancelToken: cancelToken,
        ),
      );

  Future<void> block(int userId) => _client.put(UserEndpoints.block(userId));

  Future<void> unblock(int userId) =>
      _client.delete(UserEndpoints.block(userId));

  /// 个性化推荐开关. 默认开启.
  Future<bool> personalized({CancelToken? cancelToken}) async => _personalized(
    await _client.get(
      UserEndpoints.recommendationSettings,
      cancelToken: cancelToken,
    ),
  );

  Future<void> setPersonalized({required bool personalized}) => _client.put(
    UserEndpoints.recommendationSettings,
    body: {'personalized': personalized},
  );

  static bool _blocked(Object? data) => data is Map && data['blocked'] == true;

  static bool _personalized(Object? data) =>
      !(data is Map && data['personalized'] == false);

  /// 开始换绑到 [mobile]. 返回的 `oldProofRequired` 表示提交时是否要验证旧手机或密码.
  Future<MobileCommandDto> prepareMobileChange({
    required String commandId,
    required String mobile,
  }) async => decodeJson(
    await _client.post(
      UserEndpoints.mobileCommands,
      body: {'commandId': commandId, 'mobile': mobile},
    ),
    MobileCommandDto.fromJson,
  );

  /// 给新手机 (`NEW_PHONE`) 或旧手机 (`OLD_PHONE`) 发验证码. 发送前需完成人机验证.
  Future<void> sendMobileChangeCode(
    String commandId, {
    required String type,
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    UserEndpoints.mobileCommandCodes(commandId),
    body: {'type': type},
    headers: captchaHeaders,
  );

  /// 提交换绑. 旧手机用 [oldCode] 或 [password] 证明, 不需要时都为 null.
  Future<MobileCommitDto> commitMobileChange(
    String commandId, {
    required String newCode,
    String? oldCode,
    String? password,
    required String recoveryCapability,
  }) async => decodeJson(
    await _client.post(
      UserEndpoints.mobileCommandCommit(commandId),
      body: {
        'newCode': newCode,
        'oldCode': ?oldCode,
        'password': ?password,
        'recoveryCapability': recoveryCapability,
      },
    ),
    MobileCommitDto.fromJson,
  );

  Future<SessionOutcomeDto> resumeMobileChange(
    String commandId, {
    required String recoveryCapability,
  }) async => decodeJson(
    await _client.post(
      UserEndpoints.mobileCommandResume(commandId),
      headers: {'X-Recovery-Capability': recoveryCapability},
    ),
    SessionOutcomeDto.fromJson,
  );
}

/// 换绑手机的准备结果.
@JsonSerializable(createToJson: false)
class const MobileCommandDto({
  final String? commandId,
  final bool? oldProofRequired,
}) {
  factory MobileCommandDto.fromJson(Map<String, dynamic> json) =>
      _$MobileCommandDtoFromJson(json);
}

/// 换绑手机的提交结果. [currentDevice] 为 `READY` 时 [replacement] 是本机的新会话,
/// `PENDING` 时需通过恢复接口获取, `REAUTHENTICATION_REQUIRED` 时需要重新登录.
@JsonSerializable(createToJson: false)
class const MobileCommitDto({
  final String? currentDevice,
  final SessionOutcomeDto? replacement,
}) {
  factory MobileCommitDto.fromJson(Map<String, dynamic> json) =>
      _$MobileCommitDtoFromJson(json);
}

/// `/user/followers` 和 `/user/followings` 的一项. [createdAt] 是关注的时间.
@JsonSerializable(createToJson: false)
class const FansDto({
  final int? id,
  final String? displayName,
  final String? avatar,
  final int? createdAt,
}) {
  factory FansDto.fromJson(Map<String, dynamic> json) =>
      _$FansDtoFromJson(json);
}

/// `/user/blocks` 的一项. 对方账号已注销时 [displayName] 为 null.
@JsonSerializable(createToJson: false)
class const BlockedUserDto({final int? userId, final String? displayName}) {
  factory BlockedUserDto.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserDtoFromJson(json);
}

/// `/user/userInfo` 的 `data`: 指定用户的公开资料, 统计, 以及与当前用户的关注关系.
@JsonSerializable(createToJson: false)
class const UserProfileDto({
  final String? displayName,
  final String? avatar,
  final int? earnedLikes,
  final int? fansCount,
  final int? followingsCount,
  final bool? fansVisible,
  final bool? followingsVisible,
  final bool? isFollowingMe,
  final bool? isFollowingHim,
  final int? uploadedFoodsCount,

  /// 等级, 1 到 10. 不公开对方的经验.
  final int? level,
}) {
  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);
}

/// `/user/info` 的 `data`. 字段按接口声明均为可空, 转换为领域模型时补默认值.
///
/// 该 DTO 原样存入本地缓存, 启动时先用缓存显示, 因此需要支持转回 JSON.
/// 产品不收集性别, 生日和家乡, 因此不读取这些字段.
@JsonSerializable(includeIfNull: false)
class const UserInfoDto({
  final int? id,
  final String? displayName,
  final String? userName,
  final bool? hasUsername,
  final String? avatar,
  final bool? banned,
  final String? banReason,
  final int? bannedAt,

  // TODO: 契约声明 banUntil 为 ISO-8601 字符串, 后端的 Jackson 配置实际把 `Instant` 写成 Unix 毫秒, 本字段按实际返回解析. 契约与后端统一格式后按统一的格式解析.
  /// 封禁截止时间, Unix 毫秒. null 表示永久封禁或没有期限证明.
  final int? banUntil,
  final String? phone,
  final bool? verified,
  final String? method,
  final String? verifiedEmail,
  final bool? hasPassword,
  final String? signature,
}) {
  factory UserInfoDto.fromJson(Map<String, dynamic> json) =>
      _$UserInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoDtoToJson(this);
}

@Riverpod(keepAlive: true)
UserApi userApi(Ref ref) => UserApi(ref.watch(apiClientProvider));
