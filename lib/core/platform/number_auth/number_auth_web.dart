import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/number_auth/number_auth.dart';

/// Web 不接一键登录, 只用验证码和密码登录.
NumberAuth createNumberAuth(AppConfig config) => const UnsupportedNumberAuth();
