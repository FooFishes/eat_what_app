import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';

/// 附近页地图上的店铺标记（规范 `MapPin`）：白色小圆盘里放招牌菜的圆图。
///
/// 普通 44px（里面 38px 圆图）；选中 72px（里面 64px），外圈 4px [ring] 色，下面一个 `ink` 底的店名胶囊。
/// 同时只放大一个。没有图时圆里是 `mist` 底。整个标记是一个按钮，读屏念店名。
class MapPin extends StatelessWidget {
  const new({
    super.key,
    required this.name,
    required this.image,
    required this.selected,
    required this.ring,
    required this.onTap,
  });

  final String name;
  final ImageProvider? image;
  final bool selected;
  final Color ring;
  final VoidCallback onTap;

  /// 标记整体占的大小：选中时下面还有店名胶囊。地图层按这个尺寸给 `Marker`。
  static const size = Size(160, 110);

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final outer = selected ? 72.0 : EatSize.touch;
    final inner = selected ? 64.0 : 38.0;
    final duration = context.motion(EatMotion.select);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EatTappable(
          onTap: onTap,
          label: selected ? '$name，已选中' : name,
          selected: selected,
          focusShape: const CircleBorder(),
          builder: (context, _) => AnimatedContainer(
            duration: duration,
            width: outer,
            height: outer,
            decoration: BoxDecoration(
              color: c.paper,
              shape: BoxShape.circle,
              border: selected ? Border.all(color: ring, width: 4) : null,
              boxShadow: eat.shadows.pin.outer,
            ),
            alignment: Alignment.center,
            child: ClipOval(
              child: SizedBox.square(
                dimension: inner - (selected ? 8 : 0),
                child: CoverImage(image: image),
              ),
            ),
          ),
        ),
        if (selected)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: c.ink,
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.paper,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 地图上我的位置：15px `map-me` 圆点、3px 白边，外面 48px 的 16% 光晕。
class MyLocationDot extends StatelessWidget {
  const new({super.key});

  static const size = 48.0;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Semantics(
      label: '我的位置',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.mapMe.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: c.mapMe,
            shape: BoxShape.circle,
            border: Border.all(color: c.paper, width: 3),
          ),
        ),
      ),
    );
  }
}
