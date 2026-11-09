import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/design/widgets/marker_bitmap.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/eat_test_app.dart';

void main() {
  testWidgets('缓存里的图片画进位图，锚点按排好的尺寸换算成比例', (tester) async {
    final red = await tester.runAsync(_solidPng);
    final provider = MemoryImage(red!);
    late BuildContext context;
    await pumpEat(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    await tester.runAsync(() => precacheImage(provider, context));

    final image = await tester.runAsync(
      () => MarkerBitmap.render(
        context,
        SizedBox(
          width: 40,
          height: 20,
          child: Image(image: provider, fit: BoxFit.cover),
        ),
        anchor: (size) => Offset(size.width / 2, size.height),
      ),
    );

    expect(image!.size, const Size(40, 20));
    expect(image.anchor, const Offset(0.5, 1));
    expect(await tester.runAsync(() => _centerPixel(image)), 0xFFFF0000);
  });
}

Future<Uint8List> _solidPng() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const Color(0xFFFF0000), BlendMode.src);
  final image = await recorder.endRecording().toImage(4, 4);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<int> _centerPixel(MarkerImage marker) async {
  final codec = await ui.instantiateImageCodec(marker.png);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData();
  final x = image.width ~/ 2;
  final y = image.height ~/ 2;
  final i = (y * image.width + x) * 4;
  final b = data!.buffer.asUint8List();
  return (b[i + 3] << 24) | (b[i] << 16) | (b[i + 1] << 8) | b[i + 2];
}
