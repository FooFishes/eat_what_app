import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/code_point_limit.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:eat/features/publish/widgets/bottom_bar.dart';
import 'package:eat/features/publish/widgets/map_place_list.dart';
import 'package:eat/features/publish/widgets/photo_source.dart';
import 'package:eat/features/system/base_map.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/published.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 新建店铺页面. 先按关键词搜地图上的店, 从候选里选一家; 搜不到时手动添加.
///
/// 选了候选后进入表单, 店名, 位置和地址描述按地图上的信息预填, 都可以改, 提交时带上地点的 uid.
/// 地图不可用 (没配 AK) 时直接进入手动添加的表单.
///
/// 表单的字段包括店名, 地图选点, 地址描述和选填的门头照片.
/// - 所属商圈按地图中心自动判断.
/// - 选中的地点已经有人建过店, 或附近已有同名店时显示提示. 用户可以选择已有的店, 也可以继续新建.
///
/// 创建成功后的去向:
/// - 新店进入审核时, 提示 "已提交审核" 并返回上一页. 审核通过前店铺不公开, 不能挂菜.
/// - [returnShop] 为 true 时, 带着新店返回上一页. 用于加菜页的 "换一家".
/// - 否则替换为新店的加菜页.
class NewShopPage extends ConsumerStatefulWidget {
  const new({super.key, this.initialName = '', this.returnShop = false});

  final String initialName;
  final bool returnShop;

  @override
  ConsumerState<NewShopPage> createState() => _NewShopPageState();
}

class _NewShopPageState extends ConsumerState<NewShopPage> {
  late final _search = TextEditingController(text: widget.initialName);
  late final _name = TextEditingController(text: widget.initialName);
  final _address = TextEditingController();

  /// 是否在填表单. 为 false 时显示地图候选.
  late var _editing = !_canSearch;

  /// 选中的地图候选. 手动添加时为 null.
  MapPlace? _place;

  /// 用户在 "这家店已经有了" 的提示中选择了继续新建.
  var _keepPoi = false;
  final _map = EatMapController();
  GcjPoint? _center;
  var _mapFailed = false;
  PickedPhoto? _photo;

  /// 用户在同名店提示中选择了 "不是同一家, 继续建".
  var _keepNew = false;

  /// 手指是否按在地图上.
  ///
  /// 按在地图上时禁止页面滚动, 否则纵向拖动会被页面滚动拦截, 地图无法拖动.
  var _onMap = false;
  var _busy = false;

  /// 已上传的门头照片及其存储 key. 重试提交时不重复上传.
  ({PickedPhoto photo, String key})? _uploaded;

  /// 本次新建的 `Idempotency-Key` 及对应的提交内容.
  ///
  /// 超时后重试同一份内容时复用 key, 服务端据此去重. 内容变化后换新 key, 服务端拒绝同一 key 提交不同内容.
  ({String content, String key})? _request;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(currentLocationProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  /// 地图中心. 未拖动过时取当前位置, 没有定位时取校区中心.
  GcjPoint? get _point =>
      _center ??
      ref.read(currentLocationProvider).point ??
      ref.read(currentPlaceProvider).campus?.center;

  bool get _canSearch => ref.read(placeRepositoryProvider).canSearchPlaces;

  /// 选了一个候选: 预填表单, 地图移到候选的位置.
  ///
  /// 先收起键盘: 候选页和表单共用页面骨架, 不收起时搜索框的焦点会落到店名输入框上.
  void _choose(MapPlace place) => setState(() {
    FocusManager.instance.primaryFocus?.unfocus();
    _place = place;
    _name.text = place.name;
    _address.text = place.address;
    _center = place.point;
    _keepNew = false;
    _keepPoi = false;
    _mapFailed = false;
    _editing = true;
  });

  /// 搜不到时手动添加. 店名先用搜索的关键词.
  void _addManually() => setState(() {
    FocusManager.instance.primaryFocus?.unfocus();
    _place = null;
    _name.text = _search.text.trim();
    _address.clear();
    _center = null;
    _keepNew = false;
    _mapFailed = false;
    _editing = true;
  });

  /// 从表单回到候选列表.
  void _backToCandidates() => setState(() => _editing = false);

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
    final poi = _place?.uid;
    try {
      final hub = ref.read(hubAtProvider(point)).value;
      String? photoKey;
      if (_photo case final photo?) {
        photoKey = identical(_uploaded?.photo, photo)
            ? _uploaded!.key
            : await ref
                  .read(uploaderProvider)
                  .upload(photo.bytes, biz: UploadBiz.restaurants);
        _uploaded = (photo: photo, key: photoKey);
      }
      final content = [
        name,
        address,
        point.lat,
        point.lng,
        hub?.id,
        poi,
        photoKey,
      ].join('|');
      if (_request?.content != content) {
        _request = (content: content, key: newIdempotencyKey());
      }
      final (:id, :pending) = await ref
          .read(placeRepositoryProvider)
          .createShop(
            name: name,
            address: address,
            point: point,
            hubId: hub?.id,
            poi: poi,
            photoKey: photoKey,
            idempotencyKey: _request!.key,
          );
      if (!mounted) return;
      if (pending) {
        showToast(context, '已提交审核，通过后公开');
        context.pop();
        return;
      }
      ref.read(publishedCountProvider.notifier).published();
      final shop = Shop(
        id: id,
        name: name,
        address: address,
        point: point,
        hubId: hub?.id,
        poi: poi,
        status: ShopStatus.open,
        dishCount: 0,
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

  /// 在同名店提示中选择已有的店. 已关门的店不能选.
  void _useExisting(Shop shop) {
    if (!ensureShopOpen(context, shop)) return;
    if (widget.returnShop) {
      context.pop(shop);
    } else {
      context.pushReplacement(Paths.publishDish(shop.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return PlainScaffold(
        title: '新建一家店',
        subtitle: '先在地图上找找这家店',
        slivers: [
          MapPlaceList(
            search: _search,
            onChanged: (_) => setState(() {}),
            onSelected: _choose,
            onManual: _addManually,
          ),
        ],
      );
    }
    // 从候选进来的表单, 返回时回到候选; 地图不可用时没有候选, 直接离开页面.
    final canGoBack = _canSearch;
    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToCandidates();
      },
      child: _form(context, onBack: canGoBack ? _backToCandidates : null),
    );
  }

  Widget _form(BuildContext context, {VoidCallback? onBack}) {
    final eat = context.eat;
    final c = eat.colors;
    // 定位和校区数据到达后 [_point] 才有值. 监听这两项, 数据到达时重建页面.
    ref
      ..watch(currentLocationProvider.select((s) => s.point))
      ..watch(currentPlaceProvider.select((p) => p.campus));
    final point = _point;
    final name = _name.text.trim();
    final address = _address.text.trim();
    final hub = point == null ? null : ref.watch(hubAtProvider(point));
    final place = _place;
    final existing = place == null || _keepPoi
        ? null
        : ref.watch(poiShopProvider(place.uid, place.point)).value;
    // 已经提示了同一个地点的店, 不再重复提示同名店.
    final same = point == null || _keepNew || existing != null
        ? null
        : ref.watch(sameNameShopProvider(name, point)).value;
    // 预填的店名和地址可能超出字数上限, 由用户删改.
    final nameTooLong = codePointLength(name) > PublishRules.shopNameMax;
    final addressTooLong = address.length > PublishRules.addressMax;
    final ready =
        name.isNotEmpty &&
        address.isNotEmpty &&
        !nameTooLong &&
        !addressTooLong &&
        point != null &&
        existing == null &&
        same == null;
    final mapReady = !_mapFailed && ref.watch(mapEngineProvider).available;

    return Column(
      children: [
        Expanded(
          child: PlainScaffold(
            title: '新建一家店',
            onBack: onBack,
            physics: _onMap ? const NeverScrollableScrollPhysics() : null,
            slivers: [
              SliverList.list(
                children: [
                  EatFormField(
                    label: '店名',
                    controller: _name,
                    hintText: '比如 袁记云饺',
                    autofocus: _place == null && _name.text.isEmpty,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      CodePointLengthLimitingFormatter(
                        PublishRules.shopNameMax,
                      ),
                    ],
                    trailing: _Counter(
                      codePointLength(_name.text),
                      PublishRules.shopNameMax,
                    ),
                    onChanged: (_) => setState(() => _keepNew = false),
                  ),
                  if (existing != null)
                    _ExistingNotice(
                      text: '这家店已经有了，叫「${existing.name}」',
                      onUse: () => _useExisting(existing),
                      onKeep: () => setState(() => _keepPoi = true),
                    )
                  else if (same != null && point != null)
                    _ExistingNotice(
                      text:
                          '附近已有一家「${same.name}」，'
                          '相距 ${GeoRules.formatDistance(GeoRules.distance(point, same.point))}',
                      onUse: () => _useExisting(same),
                      onKeep: () => setState(() => _keepNew = true),
                    ),
                  const SizedBox(height: EatSpace.s24),
                  Text(
                    mapReady ? '位置，拖动地图将标记对准店门口' : '位置',
                    style: eat.text.meta.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: EatSpace.s8),
                  if (mapReady && point != null)
                    Listener(
                      onPointerDown: (_) => setState(() => _onMap = true),
                      onPointerUp: (_) => setState(() => _onMap = false),
                      onPointerCancel: (_) => setState(() => _onMap = false),
                      child: _PickMap(
                        key: ValueKey(place?.uid),
                        controller: _map,
                        initial: point,
                        onMoved: (center) => setState(() => _center = center),
                        onFailed: () => setState(() => _mapFailed = true),
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
                            AsyncData() => '不在已有商圈内',
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
          note: name.isEmpty || address.isEmpty
              ? '请填写店名和地址描述'
              : nameTooLong
              ? '店名最多 ${PublishRules.shopNameMax} 个字'
              : addressTooLong
              ? '地址描述最多 ${PublishRules.addressMax} 个字'
              : null,
          child: EatButton.solid(
            widget.returnShop ? '完成' : '下一步：去加菜',
            loading: _busy,
            onPressed: ready ? _submit : null,
          ),
        ),
      ],
    );
  }
}

/// 输入框右侧的字数计数.
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
        style: eat.text.meta.copyWith(
          // 预填的内容可能超出上限, 超出时变色, 底部同时提示.
          color: count > max ? eat.colors.warn : eat.colors.inkMuted,
        ),
      ),
    );
  }
}

/// 已有店的提示: 选中的地点已经有人建过店, 或附近有同名店. 提供 "就选它" 和 "不是同一家, 继续建".
class _ExistingNotice extends StatelessWidget {
  const new({required this.text, required this.onUse, required this.onKeep});

  final String text;
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
            Text(text, style: eat.text.body.copyWith(color: c.warn)),
            Row(
              spacing: EatSpace.s10,
              children: [
                EatButton.outline('就选它', height: 36, onPressed: onUse),
                EatButton.mist('不是同一家，继续新建', height: 36, onPressed: onKeep),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 选点地图. 地图中心固定一个定位针, 用户拖动地图使针尖对准店门口.
///
/// 拖动停止后, 地图中心通过 [onMoved] 回传.
class _PickMap extends StatelessWidget {
  const new({
    super.key,
    required this.controller,
    required this.initial,
    required this.onMoved,
    required this.onFailed,
  });

  final EatMapController controller;
  final GcjPoint initial;
  final ValueChanged<GcjPoint> onMoved;
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(EatRadius.tile),
        child: Stack(
          children: [
            EatMap(
              controller: controller,
              initialCenter: mapPoint(initial),
              initialZoom: 17,
              minZoom: 13,
              // 四角被圆角裁掉, 内边距把 logo 和比例尺挪进来. 四边相等, 地图中心不变.
              insets: const EdgeInsets.all(EatSpace.s10),
              onCameraIdle: (camera, _) => onMoved(gcjOf(camera.center)),
              onFailed: onFailed,
              semanticLabel: '地图选点',
            ),
            // 针尖位于图标底部. 图标上移半个自身高度, 使针尖对准地图中心.
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

/// 门头照片. 未选择时显示虚线框和选填说明, 选择后显示照片和删除按钮.
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
                '选填，拍一张门头招牌，方便大家找到',
                style: eat.text.body.copyWith(color: c.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
