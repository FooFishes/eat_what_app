import 'package:clock/clock.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:eat/domain/rules/remote_config_rules.dart';
import 'package:eat/state/remote_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 按远程配置检查一次操作能否执行. 允许时返回 true, 否则弹出轻提示并返回 false.
///
/// [feature] 为操作所属的可关闭功能, [write] 表示操作会修改数据, 全站只读时被拦截.
/// 受限操作统一经由 `guardAction` 调用本函数; 不属于受限操作的入口 (如推送开关) 直接调用.
bool guardRemote(
  BuildContext context,
  WidgetRef ref, {
  RemoteFeature? feature,
  bool write = true,
}) {
  final gate = remoteGate(
    ref.read(remoteConfigProvider),
    feature: feature,
    write: write,
  );
  switch (gate) {
    case RemoteOpen():
      return true;
    case RemoteReadOnly(:final maintenance):
      showToast(context, readOnlyMessage(maintenance, clock.now()));
      return false;
    case RemoteFeatureOff(:final flag):
      showToast(context, featureOffMessage(flag));
      return false;
  }
}
