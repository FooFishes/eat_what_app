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

  /// [userId] 的粉丝. 对方不公开粉丝列表时失败, 业务码为 `BizCodes.permissionDenied`.
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

  /// [userId] 关注的人. 对方不公开关注列表时失败, 业务码为 `BizCodes.permissionDenied`.
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

  /// 换绑第一步: 给当前绑定的号码发验证码. 发送前需完成人机验证.
  Future<void> sendOldMobileCode({
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(UserEndpoints.mobileOldCode, headers: captchaHeaders);

  /// 换绑第二步: 给新号码 [mobile] 发验证码. 发送前需完成人机验证.
  ///
  /// 第一次调用要带旧号码的验证码 [oldCode], 服务端校验通过后 10 分钟内可以不带, 用于重发或更换新号码.
  Future<void> sendNewMobileCode({
    String? oldCode,
    required String mobile,
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    UserEndpoints.mobileNewCode,
    body: {'oldCode': ?oldCode, 'mobile': mobile},
    headers: captchaHeaders,
  );

  /// 换绑第三步: 提交新号码和它的验证码. 成功后其他设备要重新登录, 本机不受影响.
  Future<void> commitMobileChange({
    required String mobile,
    required String code,
  }) => _client.post(
    UserEndpoints.mobileCommit,
    body: {'mobile': mobile, 'code': code},
  );

  /// 补绑手机: 给 [mobile] 发验证码. 只用于还没有手机号的账号. 发送前需完成人机验证.
  Future<void> sendBindCode(
    String mobile, {
    Map<String, String> captchaHeaders = const {},
  }) => _client.post(
    UserEndpoints.bindCode,
    body: {'mobile': mobile},
    headers: captchaHeaders,
  );

  /// 补绑手机: 提交 [mobile] 和它的验证码.
  Future<void> bindMobile({required String mobile, required String code}) =>
      _client.post(
        UserEndpoints.bindMobile,
        body: {'mobile': mobile, 'code': code},
      );
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

/// `/user/userInfo` 的 `data` (`UserDtos.OtherInfo`): 指定用户的公开资料, 统计, 以及与当前用户的关系.
///
/// 产品不收集性别, 因此不读取 `gender`.
@JsonSerializable(createToJson: false)
class const UserProfileDto({
  final int? id,
  final String? displayName,
  final String? avatar,
  final String? signature,

  /// 等级, 1 到 10. 所有人可见, 经验只有本人能看.
  final int? level,

  /// 获赞: 首次发布的菜收到的赞, 加上评论和回复收到的赞. 所有人可见.
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
  final String? phone,
  final bool? verified,

  /// 认证方式: `sso` 或 `email`.
  final String? method,
  final String? verifiedEmail,
  final bool? hasPassword,
  final String? signature,
  final int? level,
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
