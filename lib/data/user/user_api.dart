import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
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
  static const mobileOldCode = '/user/mobile/change/old-code';
  static const mobileNewCode = '/user/mobile/change/new-code';
  static const mobileCommit = '/user/mobile/change/commit';
  static const bindCode = '/user/getCode';
  static const bindMobile = '/user/bindMobile';
}

/// 用户接口 (`User` 分组), 涵盖当前用户信息, 公开资料, 关注关系, 隐私设置, 屏蔽列表, 个性化推荐以及手机号绑定.
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

  /// 更新昵称, 头像和个性签名; [avatar] 为上传后得到的存储 key, 为 null 时保持原头像不变.
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

  /// 分页获取 [userId] 的粉丝列表; 若对方未公开粉丝列表, 服务端返回 `BizCodes.permissionDenied`.
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

  /// 分页获取 [userId] 的关注列表; 若对方未公开关注列表, 服务端返回 `BizCodes.permissionDenied`.
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

  /// 设置关注列表 ([following]) 与粉丝列表 ([follower]) 的公开可见性.
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

  /// 查询个性化推荐开关状态, 默认为开启.
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

  /// 换绑手机第一步, 向当前绑定号码发送验证码 (发送前需先完成人机验证).
  Future<void> sendOldMobileCode({
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(UserEndpoints.mobileOldCode, headers: captchaHeaders);

  /// 换绑手机第二步, 向新号码 [mobile] 发送验证码 (发送前需先完成人机验证).
  ///
  /// 首次调用需附带旧号码验证码 [oldCode]; 服务端校验通过后 10 分钟内可省略该参数, 用于重发验证码或更换目标号码.
  Future<void> sendNewMobileCode({
    String? oldCode,
    required String mobile,
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    UserEndpoints.mobileNewCode,
    body: {'oldCode': ?oldCode, 'mobile': mobile},
    headers: captchaHeaders,
  );

  /// 换绑手机第三步, 提交新号码及其验证码; 换绑成功后其他设备需重新登录, 本机会话保持有效.
  Future<void> commitMobileChange({
    required String mobile,
    required String code,
  }) => _client.post(
    UserEndpoints.mobileCommit,
    body: {'mobile': mobile, 'code': code},
  );

  /// 补绑手机第一步, 向 [mobile] 发送验证码 (仅适用于尚未绑定手机号的账号, 发送前需先完成人机验证).
  Future<void> sendBindCode(
    String mobile, {
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    UserEndpoints.bindCode,
    body: {'mobile': mobile},
    headers: captchaHeaders,
  );

  /// 补绑手机第二步, 提交 [mobile] 及其验证码以完成绑定.
  Future<void> bindMobile({required String mobile, required String code}) =>
      _client.post(
        UserEndpoints.bindMobile,
        body: {'mobile': mobile, 'code': code},
      );
}

/// `/user/followers` 和 `/user/followings` 的列表项 (`UserDtos.Person`), [createdAt] 为关注时间.
///
/// [isFollowingMe] 表示对方关注了当前登录用户, [isFollowingHim] 表示当前登录用户关注了对方, 不论查看的是谁的列表.
@JsonSerializable(createToJson: false)
class const FansDto({
  final int? id,
  final String? displayName,
  final String? avatar,

  /// 等级称号, 目前只有满级有 ("老吃家"), 其余为 null.
  final String? title,
  final int? createdAt,
  final bool? isFollowingMe,
  final bool? isFollowingHim,
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

/// `/user/userInfo` 返回的公开用户资料 (`UserDtos.OtherInfo`), 包含个人资料, 统计数据及与当前用户的关系.
///
/// 应用不收集性别信息, 因此忽略接口中的 `gender` 字段. 本人的资料会原样存入本地缓存, 因此需支持 `toJson`.
@JsonSerializable()
class const UserProfileDto({
  final int? id,
  final String? displayName,
  final String? avatar,
  final String? signature,

  /// 用户等级 (1–10), 对所有人可见; 经验值仅本人可见.
  final int? level,

  /// 等级称号, 目前只有满级有 ("老吃家"), 其余为 null.
  final String? title,

  /// 累计获赞数 (包含首次发布菜品, 评论及回复收到的点赞), 对所有人可见.
  final int? earnedLikes,

  /// 对方未公开粉丝列表时为 null. 查看自己时总有值.
  final int? fansCount,

  /// 对方未公开关注列表时为 null. 查看自己时总有值.
  final int? followingsCount,
  final bool? fansVisible,
  final bool? followingsVisible,
  final bool? isFollowingMe,
  final bool? isFollowingHim,

  /// 当前用户是否屏蔽了对方.
  final bool? blocked,
}) {
  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}

/// `/user/info` 返回的当前用户信息; 按接口声明全部设为可空, 并在转换为领域模型时填充默认值.
///
/// 该 DTO 会原样序列化后存入本地缓存用于启动首屏展示, 因此需支持 `toJson`. 应用不收集性别, 生日与家乡信息, 故忽略对应字段.
@JsonSerializable(includeIfNull: false)
class const UserInfoDto({
  final int? id,
  final String? displayName,
  final String? userName,
  final bool? hasUsername,
  final String? avatar,
  final String? phone,
  final bool? verified,

  /// 认证方式: `sso` 或 `email`.
  final String? method,
  final String? verifiedEmail,
  final bool? hasPassword,
  final String? signature,
  final int? level,

  /// 等级称号, 目前只有满级有 ("老吃家"), 其余为 null.
  final String? title,
  final bool? banned,
  final String? banReason,

  /// 封禁截止时间, Unix 毫秒. null 表示永久封禁.
  final int? banUntil,
}) {
  factory UserInfoDto.fromJson(Map<String, dynamic> json) =>
      _$UserInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoDtoToJson(this);
}

@Riverpod(keepAlive: true)
UserApi userApi(Ref ref) => UserApi(ref.watch(apiClientProvider));
