import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/uploader.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/code_point_limit.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:eat/features/publish/widgets/bottom_bar.dart';
import 'package:eat/features/publish/widgets/map_place_list.dart';
import 'package:eat/features/publish/widgets/photo_source.dart';
import 'package:eat/features/system/base_map.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/analytics.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/published.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 新建店铺页面: 通过关键词检索地图地点并选择候选进入表单, 未检索到时支持手动添加.
///
/// 选定地图候选后进入表单并预填店名, 位置与地址描述 (均支持修改), 提交时携带对应地点的 uid;
/// 若地图服务不可用 (未配置 AK), 则直接进入手动添加表单.
///
/// 表单字段说明:
/// - 必填项包括店名, 类型 (美食, 甜点饮品或自助), 地图选点与地址描述, 所属商圈根据地图中心位置自动判定.
/// - 选填项包括门头照片, 品类, 口味, 适合饭点 (默认午饭和晚饭) 与价位, 保持默认即可提交. 能不能点外卖在菜品上设置.
///
/// 重复店铺提示机制: 当选定地点已建店或 200 m 内存在同名店铺 (忽略空白与大小写) 时, 由服务端返回提示;
/// 该提示不强制拦截, 用户可选择已有店铺或继续新建 (同一地点允许存在多家店铺, 如食堂窗口, 继续新建时仍保留地点 uid).
/// 若提交时服务端仍返回疑似重复错误 (40017), 则展示响应中的候选店铺, 用户确认继续新建后携带 `force` 重新提交.
///
/// 创建成功后的跳转逻辑:
/// - 当 [returnShop] 为 true 时将新店对象返回上一页, 用于加菜页的 "换一家" 流程.
/// - 否则将当前页替换为新店对应的加菜页.
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

  /// 是否处于表单填写阶段, 为 false 时展示地图地点候选列表.
  late var _editing = !_canSearch;

  /// 当前选定的地图候选地点, 手动添加时为 null.
  MapPlace? _place;

  final _map = EatMapController();
  GcjPoint? _center;
  var _mapFailed = false;
  PickedPhoto? _photo;
  final _nameKey = GlobalKey();

  /// 必选的店铺类型, 用户尚未选择时为 null.
  ShopKind? _kind;
  var _categories = <ShopCategory>{};
  var _tastes = <Taste>{};
  var _meals = {MealTime.lunch, MealTime.dinner};
  PriceBand? _priceBand;

  /// 标记用户是否在重复店铺提示中选择了 "不是同一家, 继续新建", 为 true 时提交携带 `force` 参数.
  var _keepNew = false;

  /// 提交时若服务端判定疑似重复, 记录响应返回的候选店铺列表, 修改店名或位置后清空.
  List<ShopDuplicate>? _rejected;

  /// 指针当前是否按在地图区域上.
  ///
  /// 触摸地图时需禁用外层页面滚动, 避免纵向拖动手势被页面滚动容器拦截而导致地图无法平移.
  var _onMap = false;
  var _busy = false;

  /// 已上传的门头照片及对应的存储 key, 用于避免提交重试时重复上传同一图片.
  ({PickedPhoto photo, String key})? _uploaded;

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

  /// 当前地图中心坐标; 未拖动过地图时优先取当前定位, 无定位时回退至校区中心.
  GcjPoint? get _point =>
      _center ??
      ref.read(currentLocationProvider).point ??
      ref.read(currentPlaceProvider).campus?.center;

  bool get _canSearch => ref.read(placeRepositoryProvider).canSearchPlaces;

  /// 选定地图候选后预填表单并将地图中心移至该地点.
  ///
  /// 切换前需先收起键盘: 候选列表与表单共用页面骨架, 若不主动失焦, 搜索框焦点会直接转移至店名输入框.
  void _choose(MapPlace place) => setState(() {
    FocusManager.instance.primaryFocus?.unfocus();
    _place = place;
    _name.text = place.name;
    _address.text = place.address;
    _center = place.point;
    _keepNew = false;
    _rejected = null;
    _mapFailed = false;
    _editing = true;
  });

  /// 未检索到合适地点时切换为手动添加表单, 并以当前搜索关键词预填店名.
  void _addManually() => setState(() {
    FocusManager.instance.primaryFocus?.unfocus();
    _place = null;
    _name.text = _search.text.trim();
    _address.clear();
    _center = null;
    _keepNew = false;
    _rejected = null;
    _mapFailed = false;
    _editing = true;
  });

  /// 从表单视图退回至地图候选列表.
  void _backToCandidates() => setState(() => _editing = false);

  Future<void> _pickPhoto() async {
    final photos = await pickPhotos(context, ref, limit: 1, title: '门头照片');
    if (photos.isNotEmpty && mounted) setState(() => _photo = photos.first);
  }

  /// 切换多选项的选中状态; 当已选数量达到 [max] 时拒绝新增并弹出上限提示.
  Set<T> _toggle<T>(Set<T> current, T value, int max, String name) {
    if (current.contains(value)) return {...current}..remove(value);
    if (current.length >= max) {
      showToast(context, '$name最多选 $max 个');
      return current;
    }
    return {...current, value};
  }

  Future<void> _submit() async {
    final point = _point;
    final kind = _kind;
    if (point == null || kind == null) return;
    if (!await guardAction(context, ref, Capability.createShop)) return;
    setState(() => _busy = true);
    final name = _name.text.trim();
    final address = _address.text.trim();
    final poi = _place?.uid;
    final force = _keepNew;
    final meals = [...MealTime.values.where(_meals.contains)];
    final categories = [...ShopCategory.values.where(_categories.contains)];
    final tastes = [...Taste.values.where(_tastes.contains)];
    final priceBand = _priceBand;
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
      final id = await ref
          .read(placeRepositoryProvider)
          .createShop(
            name: name,
            address: address,
            point: point,
            kind: kind,
            poi: poi,
            photoKey: photoKey,
            mealTimes: meals,
            priceBand: priceBand,
            categories: categories.isEmpty ? null : categories,
            tastes: tastes.isEmpty ? null : tastes,
            force: force,
          );
      if (!mounted) return;
      ref.read(publishedCountProvider.notifier).published();
      ref
          .read(analyticsProvider)
          .track(const PublishSuccessEvent(AnalyticsTarget.restaurant));
      final shop = Shop(
        id: id,
        name: name,
        address: address,
        point: point,
        hubId: hub?.id,
        hubName: hub?.name,
        poi: poi,
        kind: kind,
        mealTimes: meals,
        priceBand: priceBand,
        categories: categories,
        tastes: tastes,
      );
      if (widget.returnShop) {
        context.pop(shop);
      } else {
        context.pushReplacement(Paths.publishDish(id));
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (shopDuplicatesOf(e) case final duplicates?) {
        await _onDuplicate(duplicates);
        return;
      }
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.createShop,
        fallback: '新建失败，请重试',
      );
    }
  }

  /// 处理服务端返回的疑似重复错误, 展示响应中的候选店铺供用户直接选用或确认继续新建.
  Future<void> _onDuplicate(List<ShopDuplicate> duplicates) async {
    showToast(context, '附近可能已有这家店');
    setState(() {
      _keepNew = false;
      _rejected = duplicates;
    });
    final field = _nameKey.currentContext;
    if (field != null && field.mounted) await Scrollable.ensureVisible(field);
  }

  /// 在重复店铺提示中选用已有店铺, 已关门的店铺禁止选中.
  ///
  /// 当处于加菜页 "换一家" 流程时, 需先请求完整的店铺详情再返回上一页.
  Future<void> _useExisting(ShopDuplicate duplicate) async {
    if (duplicate.closed) {
      showToast(context, '这家店已关门，不能加菜');
      return;
    }
    if (!widget.returnShop) {
      context.pushReplacement(Paths.publishDish(duplicate.id));
      return;
    }
    setState(() => _busy = true);
    try {
      final shop = await ref.read(placeRepositoryProvider).shop(duplicate.id);
      if (!mounted) return;
      setState(() => _busy = false);
      if (ensureShopOpen(context, shop)) context.pop(shop);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.kind != FailureKind.cancelled) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return PlainScaffold(
        title: '新建一家店',
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
    // 从候选列表进入表单时拦截返回手势以退回候选列表; 若地图不可用则无候选列表, 允许直接退出页面.
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
    final duplicate =
        (_rejected ??
                (point == null
                    ? null
                    : ref
                          .watch(
                            shopDuplicatesProvider(name, point, place?.uid),
                          )
                          .value))
            ?.firstOrNull;
    final showDuplicate = duplicate != null && !_keepNew;
    // 预填的店名和地址可能超出字数上限, 由用户删改.
    final nameTooLong = codePointLength(name) > PublishRules.shopNameMax;
    final addressTooLong = address.length > PublishRules.addressMax;
    final ready =
        name.isNotEmpty &&
        address.isNotEmpty &&
        !nameTooLong &&
        !addressTooLong &&
        point != null &&
        _kind != null &&
        _meals.isNotEmpty &&
        !showDuplicate;
    final mapReady = !_mapFailed && ref.watch(mapEngineProvider).available;
    final label = eat.text.meta.copyWith(color: c.inkMuted);
    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: EatSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: EatSpace.s8,
        children: [
          Text(title, style: label),
          child,
        ],
      ),
    );

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
                    key: _nameKey,
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
                    onChanged: (_) => setState(() {
                      _keepNew = false;
                      _rejected = null;
                    }),
                  ),
                  if (showDuplicate)
                    _ExistingNotice(
                      text: duplicate.samePlace
                          ? '这家店已经有了，叫「${duplicate.name}」'
                          : '附近已有一家「${duplicate.name}」，'
                                '相距 ${GeoRules.formatDistance(duplicate.distance.toDouble())}',
                      onUse: () => _useExisting(duplicate),
                      onKeep: () => setState(() => _keepNew = true),
                    ),
                  section(
                    '类型',
                    Wrap(
                      spacing: EatSpace.s8,
                      children: [
                        for (final kind in ShopKind.values)
                          EatChip.choice(
                            kind.label,
                            selected: kind == _kind,
                            onTap: () => setState(() => _kind = kind),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EatSpace.s24),
                  Text(mapReady ? '位置，拖动地图将标记对准店门口' : '位置', style: label),
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
                        onMoved: (center) => setState(() {
                          _center = center;
                          _rejected = null;
                        }),
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
                  section(
                    '门头照片',
                    _StorefrontPhoto(
                      photo: _photo,
                      onPick: _pickPhoto,
                      onRemove: () => setState(() => _photo = null),
                    ),
                  ),
                  section(
                    '品类，选填，最多 ${ShopRules.categoriesMax} 个',
                    Wrap(
                      spacing: EatSpace.s8,
                      children: [
                        for (final category in ShopCategory.values)
                          EatChip.tag(
                            category.label,
                            selected: _categories.contains(category),
                            onTap: () => setState(
                              () => _categories = _toggle(
                                _categories,
                                category,
                                ShopRules.categoriesMax,
                                '品类',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  section(
                    '口味，选填，最多 ${ShopRules.tastesMax} 个',
                    Wrap(
                      spacing: EatSpace.s8,
                      children: [
                        for (final taste in Taste.values)
                          EatChip.tag(
                            taste.label,
                            selected: _tastes.contains(taste),
                            onTap: () => setState(
                              () => _tastes = _toggle(
                                _tastes,
                                taste,
                                ShopRules.tastesMax,
                                '口味',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  section(
                    '适合哪顿',
                    Wrap(
                      spacing: EatSpace.s8,
                      children: [
                        for (final meal in MealTime.values)
                          EatChip.tag(
                            meal.label,
                            selected: _meals.contains(meal),
                            onTap: () => setState(
                              () => _meals = _meals.contains(meal)
                                  ? ({..._meals}..remove(meal))
                                  : {..._meals, meal},
                            ),
                          ),
                      ],
                    ),
                  ),
                  section(
                    '价位',
                    Wrap(
                      spacing: EatSpace.s8,
                      children: [
                        EatChip.choice(
                          '不填',
                          selected: _priceBand == null,
                          onTap: () => setState(() => _priceBand = null),
                        ),
                        for (final band in PriceBand.values)
                          EatChip.choice(
                            band.label,
                            selected: _priceBand == band,
                            onTap: () => setState(() => _priceBand = band),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EatSpace.s16),
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
              : _kind == null
              ? '请选择店铺类型'
              : _meals.isEmpty
              ? '至少选一个饭点'
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

/// 显示在输入框右侧的字符计数标签.
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

/// 重复店铺提示组件: 当选定地点已建店或附近存在同名店铺时展示, 并提供 "就选它" 与继续新建操作按钮.
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

/// 地图选点组件: 在地图中心固定定位针, 用户拖动地图使针尖对准店铺位置.
///
/// 拖动停止后, 地图中心坐标通过 [onMoved] 回调传出.
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
              // 地图容器四角被圆角裁剪, 通过四边相等的内边距将 logo 与比例尺向内推移, 同时保持地图中心不变.
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

/// 门头照片选择组件: 未选图时展示虚线框与选填提示, 选图后展示预览图与删除按钮.
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
