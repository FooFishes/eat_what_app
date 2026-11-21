import 'package:eat/core/platform/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('you.v50to.eat/app_icon');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() => calls = []);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  void handle(Object? Function(MethodCall call) handler) =>
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });

  test('读出系统当前的图标', () async {
    handle((_) => 'bun');
    expect(await AppIcon(supported: true).current(), LauncherIcon.bun);
    expect(calls.single.method, 'get');
  });

  test('原生返回不认识的名字或报错时为 null', () async {
    handle((_) => 'cat');
    expect(await AppIcon(supported: true).current(), isNull);

    handle((_) => throw PlatformException(code: 'failed'));
    expect(await AppIcon(supported: true).current(), isNull);
  });

  test('没有原生实现时为 null', () async {
    expect(await AppIcon(supported: true).current(), isNull);
    expect(await AppIcon(supported: true).select(LauncherIcon.bun), isFalse);
  });

  test('换图标把名字传给原生, 失败时返回 false', () async {
    handle((_) => null);
    expect(await AppIcon(supported: true).select(LauncherIcon.bun), isTrue);
    expect(calls.single.method, 'set');
    expect(calls.single.arguments, 'bun');

    handle((_) => throw PlatformException(code: 'failed'));
    expect(await AppIcon(supported: true).select(LauncherIcon.pig), isFalse);
  });

  test('不支持的平台不调原生', () async {
    handle((_) => 'pig');
    final icon = AppIcon(supported: false);
    expect(await icon.current(), isNull);
    expect(await icon.select(LauncherIcon.bun), isFalse);
    expect(calls, isEmpty);
  });
}
