import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/device/device_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_api.g.dart';

abstract final class DeviceEndpoints {
  static const register = '/device/register';
}

/// 封装 Device 接口分组. 设备注册不要求登录, 同一安装 ID 重复提交按更新处理.
class DeviceApi {
  DeviceApi(this._client);

  final ApiClient _client;

  /// 注册本机. 设备注册在后台进行, 收到协议确认业务码时不弹出确认对话框.
  Future<void> register(DeviceRegisterRequestDto request) => _client.post(
    DeviceEndpoints.register,
    body: request.toJson(),
    consentRetry: false,
  );
}

@Riverpod(keepAlive: true)
DeviceApi deviceApi(Ref ref) => DeviceApi(ref.watch(apiClientProvider));
