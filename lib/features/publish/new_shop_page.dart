import 'dart:async';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:eat/features/publish/widgets/bottom_bar.dart';
import 'package:eat/features/publish/widgets/photo_source.dart';
import 'package:eat/features/system/base_map.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/published.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 新建一家店（`G-NewShop`）：店名、地图选点、地址描述、选填的门头照片（产品 6.9）。
///
/// 所属商圈按地图中心自动判断；附近 200 m 内已有同名店时提示，可以直接选它，也可以坚持新建。
/// 建好后：[returnShop] 为 true 时带着店返回上一页（选店页的「换一家」），否则换成这家店的加菜页。
class NewShopPage extends ConsumerStatefulWidget {
  const new({super.key, this.initialName = '', this.returnShop = false});

  final String initialName;
  final bool returnShop;

  @override
  ConsumerState<NewShopPage> createState() => _NewShopPageState();
}

class _NewShopPageState extends ConsumerState<NewShopPage> {
  late final _name = TextEditingController(text: widget.initialName);
  final _address = TextEditingController();
  final _map = MapController();
  GcjPoint? _center;
  PickedPhoto? _photo;

  /// 看过同名店的提示、点了「不是同一家，继续建」。
  var _keepNew = false;

  /// 手指按在地图上：这时页面不滚动，竖着拖才拖得动地图。
  var _onMap = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(currentLocationProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _map.dispose();
    super.dispose();
  }

  /// 地图中心。还没拖过时是当前位置，没有定位时是校区中心。
  GcjPoint? get _point =>
      _center ??
      ref.read(currentLocationProvider).point ??
      ref.read(currentPlaceProvider).campus?.center;

  Future<void> _pickPhoto() async {
    final photos = await pickPhotos(context, ref, limit: 1, title: '门头照片');
    if (photos.isNotEmpty && mounted) setState(() => _photo = photos.first);
  }

  Future<void> _submit() async {
    final point = _point;
    if (point == null) return;
    if (!await guardAction(context, ref, Capability.createShop)) return;
    setState(() => _busy = true);
    final name = _name.text.trim();
    final address = _address.text.trim();
    try {
      final hub = ref.read(hubAtProvider(point)).value;
      String? photoKey;
      if (_photo case final photo?) {
        photoKey = await ref
            .read(uploaderProvider)
            .upload(photo.bytes, biz: UploadBiz.restaurants);
      }
      final id = await ref
          .read(placeRepositoryProvider)
          .createShop(
            name: name,
            address: address,
            point: point,
            hubId: hub?.id,
            photoKey: photoKey,
          );
      ref.read(publishedCountProvider.notifier).published();
      if (!mounted) return;
      final shop = Shop(
        id: id,
        name: name,
        address: address,
        point: point,
        hubId: hub?.id,
      );
      if (widget.returnShop) {
        context.pop(shop);
      } else {
        context.pushReplacement(Paths.publishDish(id));
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.createShop,
        fallback: '新建失败，请重试',
      );
    }
  }

  /// 同名店提示里点「就选它」。
  void _useExisting(Shop shop) {
    if (widget.returnShop) {
      context.pop(shop);
    } else {
      context.pushReplacement(Paths.publishDish(shop.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    // 定位和校区回来以后 [_point] 才有值，监听它们让页面跟着重画。
    ref
      ..watch(currentLocationProvider.select((s) => s.point))
      ..watch(currentPlaceProvider.select((p) => p.campus));
    final point = _point;
    final name = _name.text.trim();
    final hub = point == null ? null : ref.watch(hubAtProvider(point));
    final same = point == null || _keepNew
        ? null
        : ref.watch(sameNameShopProvider(name, point)).value;
    final ready =
        name.isNotEmpty &&
        _address.text.trim().isNotEmpty &&
        point != null &&
        same == null;
    final mapReady = ref.watch(appConfigProvider).tiandituKey.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: PlainScaffold(
            title: '新建一家店',
            physics: _onMap ? const NeverScrollableScrollPhysics() : null,
            slivers: [
              SliverList.list(
                children: [
                  EatFormField(
                    label: '店名',
                    controller: _name,
                    hintText: '比如 袁记云饺',
                    autofocus: widget.initialName.isEmpty,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        PublishRules.shopNameMax,
                      ),
                    ],
                    trailing: _Counter(
                      _name.text.length,
                      PublishRules.shopNameMax,
                    ),
                    onChanged: (_) => setState(() => _keepNew = false),
                  ),
                  if (same != null && point != null)
                    _SameNameNotice(
                      shop: same,
                      distance: GeoRules.formatDistance(
                        GeoRules.distance(point, same.point),
                      ),
                      onUse: () => _useExisting(same),
                      onKeep: () => setState(() => _keepNew = true),
                    ),
                  const SizedBox(height: EatSpace.s24),
                  Text(
                    mapReady ? '位置，拖动地图让针对准店门口' : '位置',
                    style: eat.text.meta.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: EatSpace.s8),
                  if (mapReady && point != null)
                    Listener(
                      onPointerDown: (_) => setState(() => _onMap = true),
                      onPointerUp: (_) => setState(() => _onMap = false),
                      onPointerCancel: (_) => setState(() => _onMap = false),
                      child: _PickMap(
                        controller: _map,
                        initial: point,
                        onMoved: (center) => setState(() => _center = center),
                      ),
                    )
                  else
                    Text(
                      point == null ? '正在获取位置' : '地图暂不可用，先用当前位置',
                      style: eat.text.body.copyWith(color: c.inkSoft),
                    ),
                  const SizedBox(height: EatSpace.s8),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '属于 '),
                        TextSpan(
                          text: switch (hub) {
                            AsyncData(:final value?) => value.name,
                            AsyncData() => '不在已有的商圈里',
                            _ => '判断中',
                          },
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: '，按位置自动判断'),
                      ],
                    ),
                    style: eat.text.meta.copyWith(color: c.inkSoft),
                  ),
                  const SizedBox(height: EatSpace.s24),
                  EatFormField(
                    label: '地址描述',
                    controller: _address,
                    hintText: '比如 万达金街 1 层',
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(PublishRules.addressMax),
                    ],
                    trailing: _Counter(
                      _address.text.length,
                      PublishRules.addressMax,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: EatSpace.s24),
                  Text(
                    '门头照片',
                    style: eat.text.meta.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: EatSpace.s8),
                  _StorefrontPhoto(
                    photo: _photo,
                    onPick: _pickPhoto,
                    onRemove: () => setState(() => _photo = null),
                  ),
                ],
              ),
            ],
          ),
        ),
        PublishBottomBar(
          note: name.isEmpty || _address.text.trim().isEmpty
              ? '请填写店名和地址描述'
              : null,
          child: EatButton.solid(
            widget.returnShop ? '建好了' : '建好了，去加菜',
            loading: _busy,
            onPressed: ready ? _submit : null,
          ),
        ),
      ],
    );
  }
}

/// 输入框右边的「3 / 20」。
class _Counter extends StatelessWidget {
  const new(this.count, this.max);

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return ExcludeSemantics(
      child: Text(
        '$count / $max',
        style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
      ),
    );
  }
}

/// 「附近已经有一家袁记云饺了，80 m」：「就选它」或「不是同一家，继续建」。
class _SameNameNotice extends StatelessWidget {
  const new({
    required this.shop,
    required this.distance,
    required this.onUse,
    required this.onKeep,
  });

  final Shop shop;
  final String distance;
  final VoidCallback onUse;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Padding(
      padding: const EdgeInsets.only(top: EatSpace.s10),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EatSpace.s8,
          children: [
            Text(
              '附近已经有一家${shop.name}了，$distance',
              style: eat.text.body.copyWith(color: c.warn),
            ),
            Row(
              spacing: EatSpace.s10,
              children: [
                EatButton.outline('就选它', height: 36, onPressed: onUse),
                EatButton.mist('不是同一家，继续建', height: 36, onPressed: onKeep),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 选点地图：中心固定一根针，拖动地图让针对准店门口。停下后把中心交给 [onMoved]。
class _PickMap extends StatelessWidget {
  const new({
    required this.controller,
    required this.initial,
    required this.onMoved,
  });

  final MapController controller;
  final GcjPoint initial;
  final ValueChanged<GcjPoint> onMoved;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(EatRadius.tile),
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: mapPoint(initial),
                initialZoom: 17,
                minZoom: 13,
                maxZoom: 18,
                backgroundColor: eat.colors.mapGround,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd ||
                      event is MapEventFlingAnimationEnd ||
                      event is MapEventDoubleTapZoomEnd ||
                      event is MapEventScrollWheelZoom) {
                    onMoved(gcjOf(event.camera.center));
                  }
                },
              ),
              children: const [
                BaseMapLayers(),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: MapAttribution(),
                  ),
                ),
              ],
            ),
            // 针尖对准地图中心：图标底部在正中，整个图标往上挪半个身位。
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -16),
                  child: EatIcon(EatIcons.pin, size: 36, color: eat.colors.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 门头照片：没选时是虚线框「选填，拍一张招牌，别人更好找」，选了显示照片和删除。
class _StorefrontPhoto extends StatelessWidget {
  const new({
    required this.photo,
    required this.onPick,
    required this.onRemove,
  });

  final PickedPhoto? photo;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final photo = this.photo;
    if (photo != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(EatRadius.thumbLg),
            child: Image.memory(
              photo.bytes,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              cacheWidth: 288,
              semanticLabel: '门头照片',
            ),
          ),
          const SizedBox(width: EatSpace.s8),
          EatIconButton(EatIcons.delete, label: '删掉门头照片', onPressed: onRemove),
        ],
      );
    }
    return EatTappable(
      onTap: onPick,
      label: '加门头照片',
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumbLg),
      ),
      builder: (context, _) => Surface(
        style: SurfaceStyle.dashed(c.lineStrong),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(EatRadius.thumbLg),
        ),
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: EatSpace.s8,
            children: [
              EatIcon(EatIcons.camera, size: 20, color: c.ink),
              Text(
                '选填，拍一张招牌，别人更好找',
                style: eat.text.body.copyWith(color: c.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
