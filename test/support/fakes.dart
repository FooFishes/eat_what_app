import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/network/upload_client.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/platform/location.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/state/api_hooks.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// 内存里的 [KvStore]。
class MemoryKvStore implements KvStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deletePrefix(String prefix) async =>
      values.removeWhere((key, _) => key.startsWith(prefix));
}

/// 内存里的 [SecureStore]。
class MemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// 一次请求：方法、路径、查询参数、请求头和 JSON 请求体，测试里用来断言发了什么。
class const SentRequest(
  final String method,
  final String path,
  final Map<String, dynamic> query,
  final Map<String, dynamic> headers,
  final Object? body,
) {
  String get route => '$method $path';
}

/// 假的网络适配器：按「方法 路径」返回登记好的响应，不起真服务器（技术架构 21.1）。
///
/// 每个路由登记一串响应，依次用掉，用完后一直返回最后一个；没登记的路由返回 HTTP 404。
/// 响应是一个 Map 时当作 HTTP 200 的 JSON；是 [FakeResponse] 时可以指定状态码，或者模拟连不上。
class FakeAdapter implements HttpClientAdapter {
  final _routes = <String, List<Object>>{};
  final requests = <SentRequest>[];

  /// 登记 [route]（如 `POST /auth/phone/login`）的响应。
  void on(String route, List<Object> responses) =>
      _routes[route] = [...responses];

  /// 业务成功的外壳。
  static Map<String, Object?> ok([Object? data]) => {
    'code': 0,
    'msg': 'ok',
    'data': data,
    'timestamp': 0,
  };

  /// 业务失败的外壳（HTTP 200 带非零 `code`）。
  static Map<String, Object?> fail(Object code, [String msg = 'error']) => {
    'code': code,
    'msg': msg,
    'data': null,
    'timestamp': 0,
  };

  Iterable<SentRequest> sent(String route) =>
      requests.where((r) => r.route == route);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final route = '${options.method} ${options.path}';
    requests.add(
      SentRequest(
        options.method,
        options.path,
        options.queryParameters,
        options.headers,
        options.data,
      ),
    );
    final queue = _routes[route];
    if (queue == null || queue.isEmpty) {
      return ResponseBody.fromString('{}', 404, headers: _json);
    }
    final next = queue.length > 1 ? queue.removeAt(0) : queue.first;
    if (next case FakeResponse(:final status, :final body, :final offline)) {
      if (offline) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }
      return ResponseBody.fromString(jsonEncode(body), status, headers: _json);
    }
    return ResponseBody.fromString(jsonEncode(next), 200, headers: _json);
  }

  @override
  void close({bool force = false}) {}

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };
}

/// 指定了状态码或者连不上的响应。
class const FakeResponse({
  final int status = 200,
  final Object? body,
  final bool offline = false,
}) {
  const FakeResponse.offline() : this(offline: true);
}

/// 选图：直接给出事先放好的照片，不弹系统的选择框。
class FakePhotoPicker implements PhotoPicker {
  var next = <PickedPhoto>[];

  @override
  Future<List<PickedPhoto>> pickFromGallery({required int limit}) async =>
      next.take(limit).toList();

  @override
  Future<PickedPhoto?> takePhoto() async => next.firstOrNull;
}

/// 测试用的环境配置。
const testConfig = AppConfig(
  envName: 'test',
  apiBaseUrl: 'https://api.test/api',
  webBaseUrl: 'https://eat.test',
  assetBaseUrl: 'https://img.test',
  sentryDsn: '',
  tiandituKey: '',
  privacyUrl: 'https://eat.test/privacy.html',
  termsUrl: 'https://eat.test/terms.html',
);

/// `/user/info` 的一份样例。
Map<String, Object?> userInfoJson({
  bool verified = false,
  String? method,
  bool banned = false,
  bool hasPassword = false,
}) => {
  'id': 42,
  'displayName': '天凉被破王',
  'userName': null,
  'hasUsername': false,
  'avatar': null,
  'role': 'user',
  'banned': banned,
  'banReason': banned ? '多次发布不是实拍的照片' : null,
  'bannedAt': banned ? 1792763739329 : null,
  'phone': '13812345678',
  'verified': verified,
  'method': method,
  'hasPassword': hasPassword,
};

const testUser = CurrentUser(
  id: 42,
  nickname: '天凉被破王',
  phone: '13812345678',
  hasPassword: false,
  verified: false,
  banned: false,
);

/// 认证过的 [testUser]：能点赞、收藏、打标签。
const verifiedUser = CurrentUser(
  id: 42,
  nickname: '天凉被破王',
  phone: '13812345678',
  hasPassword: false,
  verified: true,
  banned: false,
);

/// 人机验证：直接给出事先定好的结果，不弹任何东西。
class FakeHumanVerifier implements HumanVerifier {
  FakeHumanVerifier([this.outcome = const CaptchaPassed(_ticket)]);

  static const _ticket = CaptchaTicket(ticket: 't-1', randstr: 'r-1');

  CaptchaOutcome outcome;
  var calls = 0;

  @override
  Future<CaptchaOutcome> verify(
    BuildContext context,
    CaptchaParams params,
  ) async {
    calls++;
    return outcome;
  }
}

/// 定位：给定的权限和位置（WGS-84），不碰系统。默认已拒绝，发现页不弹定位说明。
class FakeLocationService implements LocationService {
  FakeLocationService({this.state = LocationAccess.blocked, this.point});

  LocationAccess state;
  ({double lat, double lng})? point;
  var requests = 0;

  @override
  Future<LocationAccess> access() async => state;

  @override
  Future<LocationAccess> request() async {
    requests++;
    return state;
  }

  @override
  Future<({double lat, double lng})?> current() async =>
      state == LocationAccess.granted ? point : null;
}

/// 一开始就是 [initial] 的登录态，跳过从本地存储恢复。
class FakeSession extends Session {
  FakeSession(this.initial);

  final SessionState initial;

  @override
  SessionState build() => initial;
}

/// 1×1 的透明 PNG，测试里所有网络图片都用它。
final transparentImage = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// 测试用的一套假环境：网络、存储都在内存里，网络层的回调接到登录态上。
class TestEnv {
  final adapter = FakeAdapter();
  final kv = MemoryKvStore();
  final secure = MemorySecureStore();
  final verifier = FakeHumanVerifier();
  final location = FakeLocationService();
  final photos = FakePhotoPicker();

  /// [session] 给定时登录态从它开始；要测登录过期，同时传 [token]，网络层会带上它。
  Future<ProviderContainer> container({
    SessionState? session,
    AuthToken? token,
    List<Override> overrides = const [],
  }) async {
    networkImageFactory = (_) => MemoryImage(transparentImage);
    final tokens = TokenStore(secure);
    if (token != null) await tokens.save(token);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        ...stateOverrides,
        appConfigProvider.overrideWithValue(testConfig),
        kvStoreProvider.overrideWithValue(kv),
        secureStoreProvider.overrideWithValue(secure),
        tokenStoreProvider.overrideWithValue(tokens),
        humanVerifierProvider.overrideWithValue(verifier),
        locationServiceProvider.overrideWithValue(location),
        photoPickerProvider.overrideWithValue(photos),
        uploadClientProvider.overrideWithValue(UploadClient(adapter: adapter)),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: testConfig.apiBaseUrl,
            tokens: tokens,
            hooks: ref.watch(apiHooksProvider),
            adapter: adapter,
          ),
        ),
        if (session != null)
          sessionProvider.overrideWith(() => FakeSession(session)),
        ...overrides,
      ],
    );
    return container;
  }
}

/// 一道菜的接口样例（`FoodVO`）。推荐接口才带店的坐标和商圈，[recommend] 为 true 时加上。
Map<String, Object?> foodJson({
  int id = 1,
  String name = '鲜虾蟹籽云吞',
  int restaurantId = 7,
  String restaurantName = '袁记云饺',
  double price = 18,
  String category = 'staple',
  String? stageColor = 'broth',
  List<String> alternates = const ['mango', 'bamboo'],
  int likes = 12,
  bool liked = false,
  bool favorite = false,
  int uploaderId = 9,
  List<Map<String, Object?>> systemTags = const [],
  bool recommend = false,
}) => {
  'id': id,
  'accountId': uploaderId,
  'uploaderName': '小林',
  'restaurantId': restaurantId,
  'restaurantName': restaurantName,
  'restaurantAddress': recommend ? '万达金街 1 层' : null,
  'restaurantGcjLng': recommend ? 117.1412 : null,
  'restaurantGcjLat': recommend ? 36.6681 : null,
  'hubId': recommend ? 3 : null,
  'hubName': recommend ? '万达金街' : null,
  'name': name,
  'description': '汤很鲜，虾仁很多',
  'price': price,
  'category': category,
  'categoryLabel': '主食',
  'pictureUrl': ['https://img.test/foods/$id.jpg'],
  'pictureKeys': ['foods/$id.jpg'],
  'systemTags': systemTags,
  'myCustomTags': <Object>[],
  'isLiked': liked,
  'isFavorite': favorite,
  'likesCount': likes,
  'mealTimes': ['lunch', 'dinner'],
  'stageColor': stageColor,
  'stageAlternates': alternates,
  'coverCrop': {'centerX': 0.5, 'centerY': 0.5, 'diameter': 1},
  'removeBackground': false,
  'createdAt': 1792763739329,
  'updatedAt': 1792763739329,
};

/// 一个分页外壳。
Map<String, Object?> pageJson(List<Object?> items, {bool hasNext = false}) => {
  'currentPage': 1,
  'items': items,
  'totalPages': 1,
  'totalItems': items.length,
  'hasNext': hasNext,
};

/// 一家店的接口样例（`RestaurantVO`）。
Map<String, Object?> restaurantJson({
  int id = 7,
  String name = '袁记云饺',
  double lat = 36.6681,
  double lng = 117.1412,
}) => {
  'id': id,
  'accountId': 9,
  'name': name,
  'address': '万达金街 1 层',
  'cityId': 1,
  'location': {
    'type': 'Point',
    'coordinates': [lng, lat],
  },
  'gcjLng': lng,
  'gcjLat': lat,
  'hubId': 3,
  'POI': null,
  'pictureUrl': <String>[],
  'createdAt': 1792763739329,
  'updatedAt': 1792763739329,
};

/// `/campus/list` 的样例：只有软件园。
final campusListJson = [
  {
    'id': 1,
    'name': '软件园',
    'gcjLng': 117.140109,
    'gcjLat': 36.667382,
    'isDefault': true,
    'open': true,
    'sort': 0,
  },
];
