import 'package:eat/core/platform/orientation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('locksPortrait', () {
    bool locks(TargetPlatform platform, Size size, {bool isWeb = false}) =>
        locksPortrait(platform, isWeb: isWeb, screenSize: size);

    test('安卓手机锁竖屏，横着拿也按最短边算', () {
      expect(locks(TargetPlatform.android, const Size(393, 851)), isTrue);
      expect(locks(TargetPlatform.android, const Size(851, 393)), isTrue);
    });

    test('最短边到 600 就算平板，不锁', () {
      expect(locks(TargetPlatform.android, const Size(599.9, 960)), isTrue);
      expect(locks(TargetPlatform.android, const Size(600, 960)), isFalse);
      expect(locks(TargetPlatform.android, const Size(1280, 800)), isFalse);
    });

    test('iOS 交给 Info.plist，不锁', () {
      expect(locks(TargetPlatform.iOS, const Size(390, 844)), isFalse);
    });

    test('Web 不锁，手机浏览器也一样', () {
      expect(
        locks(TargetPlatform.android, const Size(390, 844), isWeb: true),
        isFalse,
      );
    });

    test('尺寸未知时不锁', () {
      expect(locks(TargetPlatform.android, Size.zero), isFalse);
    });
  });

  group('OrientationLock', () {
    late List<Object?> calls;

    /// 记下每次 setPreferredOrientations 的参数, 并把屏幕设成 [size] (逻辑像素).
    OrientationLock setUpDevice(
      WidgetTester tester,
      Size size, {
      TargetPlatform platform = TargetPlatform.android,
      bool isWeb = false,
    }) {
      calls = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            calls.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.view.display.devicePixelRatio = 1;
      tester.view.display.size = size;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      addTearDown(tester.view.display.reset);
      final lock = OrientationLock(platform: platform, isWeb: isWeb);
      tester.binding.addObserver(lock);
      addTearDown(() => tester.binding.removeObserver(lock));
      return lock;
    }

    const portrait = ['DeviceOrientation.portraitUp'];
    const fold = Size(393, 851);
    const unfolded = Size(840, 900);

    testWidgets('安卓手机启动时只允许正向竖屏', (tester) async {
      await setUpDevice(tester, fold).update();
      expect(calls, [portrait]);
    });

    testWidgets('平板启动时不发平台调用', (tester) async {
      await setUpDevice(tester, unfolded).update();
      expect(calls, isEmpty);
    });

    testWidgets('折叠屏展开后恢复所有方向，合上后再锁竖屏', (tester) async {
      await setUpDevice(tester, fold).update();

      tester.view.display.size = unfolded;
      await tester.pump();
      tester.view.display.size = fold;
      await tester.pump();

      expect(calls, [portrait, <String>[], portrait]);
    });

    testWidgets('内屏展开时启动不锁，合上改用外屏后锁竖屏', (tester) async {
      await setUpDevice(tester, unfolded).update();

      tester.view.display.size = fold;
      await tester.pump();

      expect(calls, [portrait]);
    });

    testWidgets('屏幕尺寸不变时不重复调用', (tester) async {
      final lock = setUpDevice(tester, fold);
      await lock.update();
      await lock.update();

      tester.view.display.size = const Size(851, 393);
      await tester.pump();

      expect(calls, [portrait]);
    });

    testWidgets('分屏只改窗口不改屏幕，平板不会被锁', (tester) async {
      await setUpDevice(tester, unfolded).update();

      tester.view.physicalSize = const Size(420, 900);
      await tester.pump();

      expect(calls, isEmpty);
    });

    for (final (name, platform, isWeb) in [
      ('iOS', TargetPlatform.iOS, false),
      ('Web', TargetPlatform.android, true),
    ]) {
      testWidgets('$name 尺寸怎么变都不发平台调用', (tester) async {
        await setUpDevice(
          tester,
          unfolded,
          platform: platform,
          isWeb: isWeb,
        ).update();

        tester.view.display.size = fold;
        await tester.pump();

        expect(calls, isEmpty);
      });
    }

    testWidgets('锁定失败后退回原状态，下次屏幕变化时重试', (tester) async {
      setUpDevice(tester, unfolded);
      var fail = true;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method != 'SystemChrome.setPreferredOrientations') {
            return null;
          }
          calls.add(call.arguments);
          if (fail) throw PlatformException(code: 'unavailable');
          return null;
        },
      );

      tester.view.display.size = fold;
      await tester.pump();
      fail = false;
      tester.view.display.size = const Size(851, 393);
      await tester.pump();

      expect(calls, [portrait, portrait]);
    });
  });
}
