import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// 菜品插画. 文件位于 `assets/illustrations/`, 复制自 `prototype/assets/dishes/`.
///
/// 只用于空状态, 引导和演示, 不能代替用户上传的照片.
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

/// 菜品插画组件. 插画自带碗盘, 放入 `DishPlate.illustration` 时不再添加盘沿.
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
