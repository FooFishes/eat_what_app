import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// 菜品插画，文件在 `assets/illustrations/`，从 `prototype/assets/dishes/` 复制而来。
///
/// 只用于空状态、引导和演示，不能冒充用户上传的照片。
enum Illustration {
  jiaozi,
  luosifen,
  niandoubao,
  niunan,
  tieguodun,
  xiangguo,
  yangzhi,
  yuntun;

  String get asset => 'assets/illustrations/$name.svg';
}

/// 一张菜品插画，本身已经画了碗盘，放进 `DishPlate.illustration` 时不再加盘沿。
class IllustrationImage extends StatelessWidget {
  const new(this.illustration, {super.key, this.size});

  final Illustration illustration;
  final double? size;

  @override
  Widget build(BuildContext context) => SvgPicture(
    AssetBytesLoader(illustration.asset),
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
