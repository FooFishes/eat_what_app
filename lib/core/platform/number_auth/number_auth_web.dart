import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/number_auth/number_auth.dart';

/// Web 端不接入一键登录, 仅支持验证码与密码登录.
NumberAuth createNumberAuth(AppConfig config) => const UnsupportedNumberAuth();
