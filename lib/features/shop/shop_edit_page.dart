import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
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
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/features/shop/shop_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Source { camera, gallery }

/// 编辑店铺资料页, 支持修改店名, 地址描述, 门头照片, 类型, 品类, 口味, 饭点, 价位及营业状态. 能不能点外卖在菜品上设置.
///
/// - 所有已认证用户均可编辑任意店铺, 保存时校验操作权限.
/// - 仅提交发生变更的字段, 若无改动则在保存时返回上一页.
/// - 存在未保存修改时返回会弹窗确认是否放弃.
class ShopEditPage extends ConsumerWidget {
  const new({super.key, required this.shopId});

  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProvider(shopId));
    if (shop.value case final shop?) return _Form(shop: shop);
    final failure = shop.error;
    return PlainScaffold(
      title: '编辑店铺',
      slivers: [
        SliverToBoxAdapter(
          child: switch (failure) {
            AppFailure(code: BizCodes.restaurantNotFound) => const EmptyState(
              icon: EatIcons.store,
              title: '这家店已删除',
            ),
            final AppFailure failure when !shop.isLoading => FailureState(
              message: failure.message,
              onRetry: () => ref.invalidate(shopProvider(shopId)),
            ),
            _ => const RowListPlaceholder(count: 4),
          },
        ),
      ],
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const new({required this.shop});

  /// 进入页面时的原始店铺资料, 用于比对字段变更.
  final Shop shop;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final _name = TextEditingController(text: widget.shop.name);
  late final _address = TextEditingController(text: widget.shop.address ?? '');

  /// 新选的门头照片.
  PickedPhoto? _photo;

  /// 是否已移除原有的门头照片.
  var _photoRemoved = false;
  late var _kind = widget.shop.kind;
  late var _categories = {...widget.shop.categories};
  late var _tastes = {...widget.shop.tastes};
  late var _meals = {...widget.shop.mealTimes};
  late var _priceBand = widget.shop.priceBand;
  late var _closed = widget.shop.closed;

  var _busy = false;

  /// 是否已保存或确认放弃修改, 为 true 时不再拦截返回操作.
  var _leaving = false;

  /// 缓存已上传的新门头照片及其存储 key, 保存失败重试时无需重复上传.
  ({PickedPhoto photo, String key})? _uploaded;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onChanged);
    _address.addListener(_onChanged);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// 计算当前表单相对于初始店铺资料的变更内容. [photoKey] 为新门头照片上传后的存储 key, 未上传时传空字符串.
  ShopChange _change({String photoKey = ''}) {
    final shop = widget.shop;
    final name = _name.text.trim();
    final address = _address.text.trim();
    return ShopChange(
      name: name == shop.name ? null : name,
      address: address == (shop.address ?? '') ? null : address,
      photo: _photo != null
          ? (key: photoKey)
          : _photoRemoved && shop.photo != null
          ? (key: null)
          : null,
      kind: _kind == shop.kind ? null : _kind,
      mealTimes: setEquals(_meals, shop.mealTimes.toSet())
          ? null
          : [...MealTime.values.where(_meals.contains)],
      priceBand: _priceBand == shop.priceBand ? null : (band: _priceBand),
      categories: setEquals(_categories, shop.categories.toSet())
          ? null
          : [...ShopCategory.values.where(_categories.contains)],
      tastes: setEquals(_tastes, shop.tastes.toSet())
          ? null
          : [...Taste.values.where(_tastes.contains)],
      closed: _closed == shop.closed ? null : _closed,
    );
  }

  bool get _dirty => !_change().isEmpty;

  /// 表单校验未通过时的提示文案, 满足保存条件时为 null.
  String? get _problem {
    final name = _name.text.trim();
    final address = _address.text.trim();
    if (name.isEmpty || address.isEmpty) return '请填写店名和地址描述';
    if (codePointLength(name) > PublishRules.shopNameMax) {
      return '店名最多 ${PublishRules.shopNameMax} 个字';
    }
    if (codePointLength(address) > PublishRules.addressMax) {
      return '地址描述最多 ${PublishRules.addressMax} 个字';
    }
    if (_meals.isEmpty) return '至少选一个饭点';
    return null;
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_problem case final problem?) {
      showToast(context, problem);
      return;
    }
    if (!_dirty) {
      _leave();
      return;
    }
    if (!await guardAction(context, ref, Capability.editShop)) return;
    setState(() => _busy = true);
    final shopId = widget.shop.id;
    try {
      var photoKey = '';
      if (_photo case final photo?) {
        photoKey = identical(_uploaded?.photo, photo)
            ? _uploaded!.key
            : await ref
                  .read(uploaderProvider)
                  .upload(photo.bytes, biz: UploadBiz.restaurants);
        _uploaded = (photo: photo, key: photoKey);
      }
      await ref
          .read(placeRepositoryProvider)
          .editShop(shopId, _change(photoKey: photoKey));
      if (!mounted) return;
      ref
        ..invalidate(shopProvider(shopId))
        ..invalidate(shopHistoryProvider(shopId));
      showToast(context, '已保存');
      _leave();
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.editShop,
        fallback: '保存失败，请重试',
      );
    }
  }

  /// 处理返回操作, 保存过程中禁止离开, 若有未保存的改动则先确认是否放弃.
  Future<void> _back() async {
    if (_busy) return;
    if (_dirty && !await _confirmDiscard()) return;
    if (mounted) _leave();
  }

  /// 标记允许离开并退出页面. 由于 PopScope 的拦截状态在下一帧重建后才解除, 需在该帧结束后执行返回.
  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) BackFallback.back(context);
    });
  }

  Future<bool> _confirmDiscard() async =>
      await showEatDialog<bool>(
        context,
        builder: (dialog) => EatDialog(
          title: '放弃修改？',
          subtitle: '改过的店铺资料都不会保存。',
          actions: Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '放弃',
                  onPressed: () => Navigator.of(dialog).pop(true),
                ),
              ),
              Expanded(
                child: EatButton.solid(
                  '继续编辑',
                  onPressed: () => Navigator.of(dialog).pop(false),
                ),
              ),
            ],
          ),
        ),
      ) ==
      true;

  Future<void> _pickPhoto() async {
    final source = await showPanel<_Source>(
      context,
      builder: (panel) => EatPanel(
        title: '门头照片',
        subtitle: '拍一张店门口的招牌，方便大家找到',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '从相册选',
                icon: EatIcons.image,
                onPressed: () => Navigator.of(panel).pop(_Source.gallery),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '拍一张',
                icon: EatIcons.camera,
                onPressed: () => Navigator.of(panel).pop(_Source.camera),
              ),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ref.read(photoPickerProvider);
    try {
      final photo = switch (source) {
        _Source.camera => await picker.takePhoto(),
        _Source.gallery => (await picker.pickFromGallery(limit: 1)).firstOrNull,
      };
      if (photo != null && mounted) setState(() => _photo = photo);
    } on PhotoPickException catch (e) {
      if (mounted) {
        showToast(context, switch (e.reason) {
          PhotoPickFailure.denied => '请在系统设置中允许访问相机和相册',
          PhotoPickFailure.unsupported => '不支持该照片格式，请更换',
        });
      }
    } on Object {
      if (mounted) showToast(context, '照片读取失败，请重试');
    }
  }

  void _removePhoto() => setState(() {
    _photo = null;
    _photoRemoved = true;
  });

  /// 切换多选标签的选中状态. 若已达到上限 [max] 项, 则阻止继续选中并弹出提示.
  Set<T> _toggle<T>(Set<T> current, T value, int max, String name) {
    if (current.contains(value)) return {...current}..remove(value);
    if (current.length >= max) {
      showToast(context, '$name最多选 $max 个');
      return current;
    }
    return {...current, value};
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final label = eat.text.meta.copyWith(color: c.inkMuted);
    final photo = _photo;
    final photoUrl = _photoRemoved ? null : widget.shop.photo;
    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: EatSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: EatSpace.s4,
        children: [
          Text(title, style: label),
          child,
        ],
      ),
    );
    return PopScope(
      canPop: _leaving || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: PlainScaffold(
        title: '编辑店铺',
        onBack: _back,
        actions: [_SaveButton(busy: _busy, onTap: _save)],
        slivers: [
          SliverList.list(
            children: [
              EatFormField(
                label: '店名',
                controller: _name,
                hintText: '比如 袁记云饺',
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  CodePointLengthLimitingFormatter(PublishRules.shopNameMax),
                ],
                trailing: _Counter(
                  codePointLength(_name.text),
                  PublishRules.shopNameMax,
                ),
              ),
              const SizedBox(height: EatSpace.s24),
              EatFormField(
                label: '地址描述',
                controller: _address,
                hintText: '比如 万达金街 1 层',
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  CodePointLengthLimitingFormatter(PublishRules.addressMax),
                ],
                trailing: _Counter(
                  codePointLength(_address.text),
                  PublishRules.addressMax,
                ),
              ),
              section(
                '门头照片',
                _PhotoField(
                  image: photo != null
                      ? MemoryImage(photo.bytes)
                      : networkImage(photoUrl, width: 96),
                  onPick: _pickPhoto,
                  onRemove: _removePhoto,
                ),
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
              section(
                '品类，最多 ${ShopRules.categoriesMax} 个',
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
                '口味，最多 ${ShopRules.tastesMax} 个',
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
              EatSwitch(
                label: '这家店已关门',
                description: '关门的店不出现在附近和推荐里，也不能再加菜',
                value: _closed,
                onChanged: (value) => setState(() => _closed = value),
              ),
              if (_problem case final problem?)
                Padding(
                  padding: const EdgeInsets.only(top: EatSpace.s16),
                  child: Text(
                    problem,
                    style: eat.text.meta.copyWith(color: c.warn),
                  ),
                ),
              const SizedBox(height: EatSpace.s24),
            ],
          ),
        ],
      ),
    );
  }
}

/// 顶栏右侧的 "保存" 按钮.
class _SaveButton extends StatelessWidget {
  const new({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return EatTappable(
      onTap: busy ? null : onTap,
      label: '保存',
      builder: (context, _) => SizedBox(
        height: EatSize.touch,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            widthFactor: 1,
            child: Text(
              busy ? '保存中' : '保存',
              style: eat.text.body.copyWith(
                fontWeight: FontWeight.w600,
                color: busy ? c.disabledFg : c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 输入框右侧的字数计数器, 超出上限时以警示色高亮.
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
          color: count > max ? eat.colors.warn : eat.colors.inkMuted,
        ),
      ),
    );
  }
}

/// 门头照片编辑区, 已有照片时展示预览图与删除按钮, 未设置时展示虚线框与选填提示.
class _PhotoField extends StatelessWidget {
  const new({
    required this.image,
    required this.onPick,
    required this.onRemove,
  });

  final ImageProvider? image;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final image = this.image;
    if (image != null) {
      return Row(
        children: [
          EatTappable(
            onTap: onPick,
            label: '换门头照片',
            focusShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(EatRadius.thumbLg),
            ),
            builder: (context, _) => ClipRRect(
              borderRadius: const BorderRadius.all(EatRadius.thumbLg),
              child: Image(
                image: image,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
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
