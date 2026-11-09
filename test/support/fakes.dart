import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/network/upload_client.dart';
import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/platform/hot_update.dart';
import 'package:eat/core/platform/location.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/router/deep_links.dart';
import 'package:eat/state/api_hooks.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// 内存实现的 [KvStore].
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

/// 内存实现的 [SecureStore].
class MemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// 一次已发送的请求, 供测试断言请求内容.
class const SentRequest(
  final String method,
  final String path,
  final Map<String, dynamic> query,
  final Map<String, dynamic> headers,
  final Object? body,
) {
  String get route => '$method $path';
}

/// 模拟的网络适配器. 按 "方法 路径" 返回预先登记的响应, 不启动真实服务器.
///
/// - 每个路由登记一组响应, 按顺序消耗. 只剩最后一个时重复返回该响应.
/// - 未登记的路由返回 HTTP 404.
/// - 响应为 Map 时作为 HTTP 200 的 JSON 返回.
/// - 响应为 [FakeResponse] 时可以指定状态码或模拟网络不可达.
class FakeAdapter implements HttpClientAdapter {
  final _routes = <String, List<Object>>{};
  final requests = <SentRequest>[];

  /// 登记 [route] 的响应. [route] 形如 `POST /auth/phone/login`.
  void on(String route, List<Object> responses) =>
      _routes[route] = [...responses];

  /// 登记匹配 [pattern] 的路由的响应, 用于路径里带随机 id 的请求. 精确登记的路由优先.
  void onPattern(RegExp pattern, List<Object> responses) =>
      _patterns.add((pattern, [...responses]));

  final _patterns = <(RegExp, List<Object>)>[];

  /// 业务成功的响应外壳.
  static Map<String, Object?> ok([Object? data]) => {
    'code': 0,
    'msg': 'ok',
    'data': data,
    'timestamp': 0,
  };

  /// 业务失败的响应外壳: HTTP 200, `code` 非零.
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
    final queue =
        _routes[route] ??
        _patterns.where((p) => p.$1.hasMatch(route)).firstOrNull?.$2;
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

/// 指定状态码或模拟网络不可达的响应.
class const FakeResponse({
  final int status = 200,
  final Object? body,
  final bool offline = false,
}) {
  const FakeResponse.offline() : this(offline: true);
}

/// 模拟的选图服务. 直接返回预置的照片, 不打开系统选择器.
class FakePhotoPicker implements PhotoPicker {
  var next = <PickedPhoto>[];

  @override
  Future<List<PickedPhoto>> pickFromGallery({required int limit}) async =>
      next.take(limit).toList();

  @override
  Future<PickedPhoto?> takePhoto() async => next.firstOrNull;

  /// 最近一次裁切的参数.
  ({double centerX, double centerY, double diameter})? lastCrop;

  @override
  Future<Uint8List> cropSquare(
    PickedPhoto photo, {
    required double centerX,
    required double centerY,
    required double diameter,
    int size = 512,
  }) async {
    lastCrop = (centerX: centerX, centerY: centerY, diameter: diameter);
    return photo.bytes;
  }
}

/// 测试用的环境配置.
const testConfig = AppConfig(
  envName: 'test',
  apiBaseUrl: 'https://api.test/api',
  webBaseUrl: 'https://eat.test',
  sentryDsn: '',
  baiduMapAkAndroid: '',
  baiduMapAkIos: '',
  baiduMapAkWeb: '',
  privacyUrl: 'https://eat.test/privacy.html',
  termsUrl: 'https://eat.test/terms.html',
);

/// `/user/info` 的响应数据样例.
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

/// 已认证版本的 [testUser], 具备点赞, 收藏和打标签的权限.
const verifiedUser = CurrentUser(
  id: 42,
  nickname: '天凉被破王',
  phone: '13812345678',
  hasPassword: false,
  verified: true,
  banned: false,
);

/// 模拟的人机验证. 直接返回预设结果, 不显示任何界面.
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

/// 模拟的定位服务. 返回预设的权限和 WGS-84 坐标, 不访问系统.
///
/// 默认权限为永久拒绝, 发现页因此不弹出定位说明.
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

/// 热更新. 默认不可用, 与 `flutter build` 的包一致.
class FakeShorebirdUpdater implements ShorebirdUpdater {
  @override
  bool isAvailable = false;

  int? patch;
  var status = UpdateStatus.upToDate;
  Object? updateError;
  var checks = 0;
  var updates = 0;

  @override
  Future<Patch?> readCurrentPatch() async =>
      patch == null ? null : Patch(number: patch!);

  @override
  Future<Patch?> readNextPatch() => readCurrentPatch();

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async {
    checks++;
    return status;
  }

  @override
  Future<void> update({UpdateTrack? track}) async {
    updates++;
    if (updateError case final error?) throw error;
  }
}

/// 以 [initial] 为初始状态的登录态, 跳过从本地存储恢复.
class FakeSession extends Session {
  FakeSession(this.initial);

  final SessionState initial;

  @override
  SessionState build() => initial;
}

/// 1×1 透明 PNG. 测试中的网络图片统一使用这张图.
final transparentImage = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// 由测试发出外部链接的 [LinkSource].
class FakeLinkSource implements LinkSource {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => _controller.stream;

  /// 模拟系统向 App 传入外部链接 [link].
  void open(Uri link) => _controller.add(link);
}

/// 不起平台视图的地图. 记下最近一次 build 的地图, 测试据此断言, 也能调它的回调模拟地图事件.
class FakeMapEngine implements MapEngine {
  EatMap? last;

  @override
  bool get available => true;

  @override
  Widget build(EatMap map) {
    last = map;
    return const ColoredBox(color: EatPalette.mapGround);
  }
}

/// 测试用的模拟环境. 网络和存储都在内存中, 网络层回调连接到登录态.
class TestEnv {
  final adapter = FakeAdapter();
  final kv = MemoryKvStore();
  final secure = MemorySecureStore();
  final verifier = FakeHumanVerifier();
  final location = FakeLocationService();
  final photos = FakePhotoPicker();
  final updater = FakeShorebirdUpdater();
  final links = FakeLinkSource();

  /// 创建 Provider 容器. 给定 [session] 时以 [session] 为初始登录态.
  ///
  /// 测试登录过期时需同时传入 [token], 网络层会在请求中携带该凭证.
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
        linkSourceProvider.overrideWithValue(links),
        hotUpdateProvider.overrideWithValue(HotUpdate(updater)),
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

/// 菜品接口 (`FoodVO`) 的响应样例.
///
/// 店铺坐标和商圈只出现在推荐接口中, [recommend] 为 true 时添加.
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
  'createdAt': 1792763739329,
  'updatedAt': 1792763739329,
};

/// 分页外壳样例.
Map<String, Object?> pageJson(List<Object?> items, {bool hasNext = false}) => {
  'currentPage': 1,
  'items': items,
  'totalPages': 1,
  'totalItems': items.length,
  'hasNext': hasNext,
};

/// 餐厅接口 (`RestaurantVO`) 的响应样例.
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
  'operatingStatus': 'OPEN',
  'permanentlyClosed': false,
  'visibleFoodCount': 0,
  'ratingSummaryState': 'SYNC_PENDING',
  'signatureFoods': <Object>[],
  'matchedFoods': <Object>[],
  'publicTastes': <Object>[],
  'publicTastesState': 'SYNC_PENDING',
  'personalState': 'NOT_LOGGED_IN',
  'createdAt': 1792763739329,
  'updatedAt': 1792763739329,
};

/// `/campus/list` 的响应样例, 只含软件园校区.
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
