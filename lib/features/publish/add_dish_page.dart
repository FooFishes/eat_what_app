import 'dart:async';

import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/code_point_limit.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:eat/features/publish/crop_page.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:eat/features/publish/widgets/bottom_bar.dart';
import 'package:eat/features/publish/widgets/photo_source.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/published.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 发布流程第 2 步加菜, 以及编辑已有的菜.
///
/// - 舞台: 封面和封面的舞台色.
/// - 抽屉: 照片, 店, 菜名, 价格, 分类, 口味, 招牌菜和 "说两句".
///
/// 发布新菜:
/// - 照片添加后立即在后台上传. 添加第一张照片后自动打开 "调整照片".
/// - 菜名已填, 封面已上传且还没选分类时, 按菜名和照片识别一次分类和口味并预选.
/// - 发布成功后关闭发布流程的所有页面, 再打开新发布的菜.
///
/// 编辑:
/// - 预填这道菜现有的内容, 不能换店. 只提交改动的字段, 没有改动时不能保存.
/// - 照片只能整组更换. 不换照片时不提交照片, 舞台色, 备选色和取景.
/// - 没有从详情页带入菜品时 (如在 Web 上刷新), 按 id 读取详情.
///
/// 已填写或已改动时返回需要确认. 草稿不保存.
class AddDishPage extends ConsumerWidget {
  const new({super.key, required int this.shopId})
    : dishId = null,
      initial = null;

  const new edit({super.key, required int this.dishId, this.initial})
    : shopId = null;

  /// 发布新菜时所在的店. 编辑时为 null.
  final int? shopId;

  /// 要编辑的菜. 发布新菜时为 null.
  final int? dishId;

  /// 从详情页带入的菜. 为 null 时按 [dishId] 读取.
  final Dish? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishId = this.dishId;
    if (dishId == null) return _DishForm(shopId: shopId!);
    if (initial case final dish?) {
      return _DishForm(shopId: dish.shopId, original: dish);
    }
    final detail = ref.watch(dishToEditProvider(dishId));
    if (detail.value case final dish?) {
      return _DishForm(shopId: dish.shopId, original: dish);
    }
    final failed = detail.hasError && !detail.isLoading;
    return StageScaffold(
      stage: StageColor.broth,
      topBar: _TopBar(step: false, onBack: () => _backToDish(context, dishId)),
      stageContent: failed ? const SizedBox() : const StagePlaceholder(),
      sheetSlivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: SliverToBoxAdapter(
            child: failed
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
                    child: FailureState(
                      message: switch (detail.error) {
                        AppFailure(:final message) => message,
                        _ => null,
                      },
                      onRetry: () => ref.invalidate(dishToEditProvider(dishId)),
                    ),
                  )
                : const RowListPlaceholder(count: 3),
          ),
        ),
      ],
    );
  }
}

/// 离开编辑页. 有上一页时返回上一页, 否则 (如在 Web 上刷新后) 前往这道菜的详情.
void _backToDish(BuildContext context, int dishId) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  } else {
    context.go(Paths.dish(dishId));
  }
}

/// 价格输入框的初始文字, 如 "18" "18.5". 没有价格时为空.
String _priceInput(double? price) => price == null
    ? ''
    : price.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// 招牌菜已满时的就地提示.
const _signatureFullText = '这家店已有 3 道招牌菜，先取消一道';

class _DishForm extends ConsumerStatefulWidget {
  const new({required this.shopId, this.original});

  final int shopId;

  /// 正在编辑的菜. 发布新菜时为 null.
  final Dish? original;

  @override
  ConsumerState<_DishForm> createState() => _DishFormState();
}

class _DishFormState extends ConsumerState<_DishForm> {
  /// 菜名或封面变化后, 等待多久再识别分类和口味. 避免用输入到一半的菜名识别.
  static const _suggestDelay = Duration(seconds: 1);

  late int _shopId = widget.shopId;

  /// 通过 "换一家" 选中的店. 不为 null 时直接使用, 不再请求店铺资料.
  Shop? _changedShop;
  late final _draft = draftProvider(original: widget.original);
  late final _name = TextEditingController(text: widget.original?.name);

  /// 编辑时价格输入框的初始文字. 文字没有改动时价格视为没有改动.
  ///
  /// 后端允许两位小数, 发布时只允许一位. 原价按发布的格式校验会被判为不合法, 因此不改动时不校验.
  late final _initialPrice = _priceInput(widget.original?.price);
  late final _price = TextEditingController(text: _initialPrice);
  late final _note = TextEditingController(text: widget.original?.description);
  var _busy = false;

  /// 发布或保存时服务端判定重名, 返回的已有菜品 id.
  int? _duplicateId;

  /// 发布或保存时服务端返回招牌菜已满. 用户再次切换招牌菜开关后清除.
  var _signatureFull = false;
  Timer? _suggestTimer;
  late final AppLifecycleListener _lifecycle;

  bool get _editing => widget.original != null;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(_draft.notifier).retryFailedOnce(),
    );
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
    _lifecycle.dispose();
    _name.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  /// 价格是否没有改动. 只在编辑时成立.
  bool get _priceUnchanged => _editing && _price.text == _initialPrice;

  /// 编辑时相对原菜的改动. 没有改动或不在编辑时为 null.
  DishChange? _change(PublishDraft draft) {
    final original = widget.original;
    if (original == null) return null;
    return draft.changeFrom(
      original,
      name: _name.text.trim(),
      price: _priceUnchanged ? null : PublishRules.parsePrice(_price.text),
      description: _note.text.trim(),
    );
  }

  bool get _dirty {
    final draft = ref.read(_draft);
    if (_editing) return _change(draft) != null || !_priceUnchanged;
    return draft.photos.isNotEmpty ||
        _name.text.trim().isNotEmpty ||
        _price.text.trim().isNotEmpty ||
        _note.text.trim().isNotEmpty;
  }

  Future<void> _leave() async {
    if (_dirty && !await _confirmLeave()) return;
    if (!mounted) return;
    switch (widget.original) {
      case final original?:
        _backToDish(context, original.id);
      case null:
        BackFallback.back(context);
    }
  }

  Future<bool> _confirmLeave() async =>
      await showEatDialog<bool>(
        context,
        builder: (dialog) => EatDialog(
          icon: EatIcons.warning,
          title: _editing ? '放弃本次修改？' : '放弃发布这道菜？',
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
      ) ??
      false;

  Future<void> _addPhotos() async {
    final draft = ref.read(_draft);
    final room = PublishRules.photosMax - draft.photos.length;
    if (room <= 0) return;
    final photos = await pickPhotos(context, ref, limit: room);
    if (!mounted || photos.isEmpty) return;
    final first = ref.read(_draft.notifier).addPhotos(photos);
    if (first) await _crop();
  }

  /// 打开 "调整照片" 调整封面.
  Future<void> _crop() async {
    final notifier = ref.read(_draft.notifier);
    final draft = ref.read(_draft);
    final cover = draft.photos.firstOrNull;
    final sample = notifier.coverSample();
    if (cover == null || sample == null) return;
    final result = await Navigator.of(context, rootNavigator: true).push(
      CropPage.route(
        image: cover.image,
        width: cover.photo.width,
        height: cover.photo.height,
        sample: sample,
        crop: draft.crop,
        fallback: draft.category?.stage ?? StageColor.broth,
        dishName: _name.text.trim(),
        picked: draft.pickedStage,
      ),
    );
    if (result == null || !mounted) return;
    notifier.applyCrop(result.crop, result.suggestion, picked: result.picked);
  }

  Future<void> _changeShop() async {
    final shop = await context.push<Shop>(Paths.publishChangeShop);
    if (shop == null || !mounted || !ensureShopOpen(context, shop)) return;
    setState(() {
      _shopId = shop.id;
      _changedShop = shop;
      _duplicateId = null;
    });
  }

  Future<void> _photoActions(DraftPhoto photo, {required bool cover}) async {
    final notifier = ref.read(_draft.notifier);
    await showPanel<void>(
      context,
      builder: (panel) {
        void run(VoidCallback action) {
          Navigator.of(panel).pop();
          action();
        }

        return EatPanel(
          title: cover ? '封面' : '这张照片',
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: EatSpace.s10,
            children: [
              if (photo.status == UploadStatus.failed)
                EatButton.solid(
                  '重新上传',
                  onPressed: () => run(() => notifier.retry(photo.id)),
                ),
              if (cover)
                EatButton.outline(
                  '调整照片',
                  onPressed: () => run(() => unawaited(_crop())),
                )
              else
                EatButton.outline(
                  '设为封面',
                  onPressed: () => run(() {
                    notifier.makeCover(photo.id);
                    unawaited(_crop());
                  }),
                ),
              EatButton.mist(
                '删掉这张',
                onPressed: () => run(() => notifier.remove(photo.id)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _publish() async {
    if (!await guardAction(context, ref, Capability.publishDish) || !mounted) {
      return;
    }
    final shop = _changedShop ?? ref.read(shopProvider(_shopId)).value;
    if (shop != null && !ensureShopOpen(context, shop)) return;
    final draft = ref.read(_draft);
    final price = PublishRules.parsePrice(_price.text);
    final category = draft.category;
    if (price == null || category == null || draft.uploading) return;
    if (draft.hasFailedUpload) {
      showToast(context, '有照片未上传成功，请重试或删除');
      return;
    }
    setState(() => _busy = true);
    final dish = NewDish(
      shopId: _shopId,
      name: _name.text.trim(),
      imageKeys: [for (final p in draft.photos) p.key!],
      price: price,
      category: category,
      stage: draft.stage,
      stageAlternates: draft.alternates,
      crop: draft.crop,
      tags: draft.tasteList,
      signature: draft.signature,
      description: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    try {
      final id = await ref.read(foodRepositoryProvider).publish(dish);
      ref.read(publishedCountProvider.notifier).published();
      if (mounted) _finish(id);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (_handleConflict(e)) return;
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.publishDish,
        fallback: '发布失败，请重试',
      );
    }
  }

  /// 提交编辑, 只提交改动的字段. 成功后通知详情, "我的" 和店铺菜单刷新, 再返回详情.
  Future<void> _save(Dish original) async {
    if (!await guardAction(context, ref, Capability.editDish) || !mounted) {
      return;
    }
    final draft = ref.read(_draft);
    if (draft.uploading) return;
    if (draft.hasFailedUpload) {
      showToast(context, '有照片未上传成功，请重试或删除');
      return;
    }
    final change = _change(draft);
    if (change == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(foodRepositoryProvider).edit(original.id, change);
      ref.read(publishedCountProvider.notifier).published();
      if (!mounted) return;
      showToast(context, '已保存');
      _backToDish(context, original.id);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (_handleConflict(e)) return;
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.editDish,
        fallback: '保存失败，请重试',
      );
    }
  }

  /// 就地处理发布和保存时的两种冲突, 处理了返回 true.
  ///
  /// - 重名: 菜名下提示已有的菜.
  /// - 招牌菜已满: 招牌菜开关下提示. 该码含义随接口而定, 只在本次标了招牌菜时按招牌菜已满处理.
  bool _handleConflict(AppFailure e) {
    switch (e.code) {
      case BizCodes.duplicateDish:
        final data = e.data;
        final id = data is Map ? data['id'] : null;
        setState(() => _duplicateId = id is num ? id.toInt() : null);
        showToast(context, e.message);
        return true;
      case BizCodes.stateNotAllowed when ref.read(_draft).signature:
        setState(() => _signatureFull = true);
        return true;
    }
    return false;
  }

  /// 菜名或封面变化后, 等输入停止再识别分类和口味. 只在发布新菜时识别.
  void _scheduleSuggest() {
    if (_editing) return;
    _suggestTimer?.cancel();
    _suggestTimer = Timer(_suggestDelay, _suggest);
  }

  void _suggest() {
    if (!mounted) return;
    final name = _name.text.trim();
    // 拼音输入法组字期间, 输入框中是拼音字母而不是菜名. 组字结束时菜名变化, 会再次触发.
    if (name.isEmpty || _name.value.composing.isValid) return;
    // 识别接口要求认证. 没有权限时不请求, 发布时由拦截对话框说明.
    final status = ref.read(accountStatusProvider);
    if (checkPermission(status, Capability.publishDish) is! Allowed) return;
    final note = _note.text.trim();
    unawaited(
      ref
          .read(_draft.notifier)
          .suggest(
            name: name,
            shopId: _shopId,
            description: note.isEmpty ? null : note,
          ),
    );
  }

  void _toggleTaste(Taste taste) {
    if (!ref.read(_draft.notifier).toggleTaste(taste)) {
      showToast(context, '口味最多选 ${PublishRules.tagsMax} 个');
    }
  }

  void _setSignature(bool value) {
    setState(() => _signatureFull = false);
    ref.read(_draft.notifier).setSignature(value);
  }

  /// 关闭发布流程的所有页面, 再压入新发布的菜.
  ///
  /// - 先关闭再压入, 用户从菜品详情返回时回到发起发布的页面, 而不是回到发布流程.
  ///
  /// 轻提示在离开页面前显示. 提示插入根 Overlay, 页面关闭后继续显示.
  /// 根 Navigator 自身的 context 位于其 Overlay 之上, 以该 context 查找 Overlay 会失败, 提示不显示.
  void _finish(int id) {
    showToast(context, '发布成功');
    final router = GoRouter.of(context);
    while (router.canPop() &&
        router.state.matchedLocation.startsWith(Paths.publish)) {
      router.pop();
    }
    final stillPublishing = router.state.matchedLocation.startsWith(
      Paths.publish,
    );
    if (stillPublishing) {
      router.go(Paths.dish(id));
    } else {
      unawaited(router.push(Paths.dish(id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(_draft);
    ref.listen(_draft.select((d) => d.photos.firstOrNull?.key), (_, key) {
      if (key != null) _scheduleSuggest();
    });
    final original = widget.original;
    final shopName = switch (original?.shopName) {
      final name? => name,
      null => (_changedShop ?? ref.watch(shopProvider(_shopId)).value)?.name,
    };
    final name = _name.text.trim();
    final price = _priceUnchanged
        ? original?.price
        : PublishRules.parsePrice(_price.text);
    // 编辑时菜名的查重键没变, 同名的只会是这道菜自己, 不必查重.
    final checkName =
        original == null ||
        PublishRules.dishNameKey(name) !=
            PublishRules.dishNameKey(original.name);
    final sameName = checkName
        ? ref.watch(sameNameDishProvider(_shopId, name)).value
        : null;
    final duplicateId =
        (sameName != null && sameName.id != original?.id
            ? sameName.id
            : null) ??
        _duplicateId;
    final missing = PublishRules.missingText(
      photo: original != null || draft.photos.isNotEmpty,
      name: name.isNotEmpty,
      price: price != null || _priceUnchanged,
      category:
          draft.category != null ||
          (original != null && original.category == null),
    );
    final signatureFull = _signatureFull && draft.signature;
    final replacing = draft.photos.isNotEmpty;
    final media = MediaQuery.of(context);

    String? note;
    var label = original == null ? '发布' : '保存';
    VoidCallback? onPressed = switch (original) {
      final original? => () => unawaited(_save(original)),
      null => _publish,
    };
    if (missing != null) {
      note = missing;
      onPressed = null;
    } else if (duplicateId != null) {
      note = original == null ? '这家店已有这道菜，去看看再说两句' : '这家店已有同名的菜，换个菜名';
      onPressed = null;
    } else if (signatureFull) {
      note = _signatureFullText;
      onPressed = null;
    } else if (draft.hasFailedUpload) {
      note = '有照片未上传成功，点照片重试或删除';
      onPressed = null;
    } else if (draft.uploading) {
      label = '照片上传中 ${(draft.uploadProgress * 100).round()}%';
      onPressed = null;
    } else if (original != null && _change(draft) == null) {
      onPressed = null;
    }

    final ImageProvider? cover;
    final CoverCrop crop;
    final StageColor stage;
    if (original != null && !replacing) {
      cover = networkImage(original.cover);
      crop = original.crop;
      stage = original.stage;
    } else {
      cover = draft.photos.firstOrNull?.image;
      crop = draft.crop;
      stage = draft.stage;
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: StageScaffold(
                    stage: stage,
                    topBar: _TopBar(onBack: _leave, step: original == null),
                    stageContent: _StageContent(
                      cover: cover,
                      crop: crop,
                      sampled: replacing,
                      category: draft.category,
                      name: name,
                      price: price,
                      onAdd: _addPhotos,
                      onCover: replacing ? _crop : _addPhotos,
                      coverLabel: replacing ? '调整照片' : '换照片',
                    ),
                    sheetSlivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EatSpace.s20,
                        ),
                        sliver: SliverList.list(
                          children: [
                            if (original != null && !replacing)
                              _ExistingPhotos(
                                images: original.images,
                                onReplace: _addPhotos,
                              )
                            else
                              _PhotoStrip(
                                photos: draft.photos,
                                onAdd: _addPhotos,
                                onTap: _photoActions,
                              ),
                            if (original != null && replacing)
                              _ReplacingNote(
                                count: original.images.length,
                                onUndo: ref.read(_draft.notifier).clearPhotos,
                              ),
                            const SizedBox(height: EatSpace.s16),
                            _ShopLine(
                              name: shopName,
                              onChange: original == null ? _changeShop : null,
                            ),
                            const SizedBox(height: EatSpace.s16),
                            EatFormField(
                              label: '菜名',
                              controller: _name,
                              hintText: '比如 鲜虾蟹籽云吞',
                              textInputAction: TextInputAction.next,
                              inputFormatters: const [
                                CodePointLengthLimitingFormatter(
                                  PublishRules.dishNameMax,
                                ),
                              ],
                              onChanged: (_) {
                                setState(() => _duplicateId = null);
                                _scheduleSuggest();
                              },
                            ),
                            if (duplicateId != null)
                              _DuplicateNotice(
                                name: sameName?.name ?? name,
                                onOpen: () =>
                                    context.push(Paths.dish(duplicateId)),
                              ),
                            const SizedBox(height: EatSpace.s16),
                            EatFormField.price(
                              label: '价格',
                              controller: _price,
                              hintText: '0',
                              errorText: _priceUnchanged
                                  ? null
                                  : PublishRules.priceError(_price.text),
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: EatSpace.s24),
                            _Group(
                              title: '分类',
                              note: draft.preselected ? '按照片预选，可以改' : null,
                              child: Wrap(
                                spacing: EatSpace.s8,
                                children: [
                                  for (final c in DishCategory.values)
                                    EatChip.choice(
                                      c.label,
                                      selected: draft.category == c,
                                      onTap: () => ref
                                          .read(_draft.notifier)
                                          .setCategory(c),
                                    ),
                                ],
                              ),
                            ),
                            _Group(
                              title: '口味，最多 ${PublishRules.tagsMax} 个',
                              child: _Tastes(
                                selected: draft.tastes,
                                onToggle: _toggleTaste,
                              ),
                            ),
                            _Signature(
                              value: draft.signature,
                              full: signatureFull,
                              onChanged: _setSignature,
                            ),
                            const SizedBox(height: EatSpace.s16),
                            _Group(
                              title: '说两句，选填',
                              child: _NoteField(
                                controller: _note,
                                onChanged: () => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PublishBottomBar(
                note: note,
                child: EatButton.solid(
                  label,
                  loading: _busy,
                  onPressed: onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶栏: 返回, 发布新菜时右侧显示步骤 "2 / 2".
class _TopBar extends StatelessWidget {
  const new({required this.onBack, required this.step});

  final VoidCallback onBack;
  final bool step;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    return Row(
      children: [
        EatBackButton(onPressed: onBack),
        const Spacer(),
        if (step)
          Semantics(
            label: '第 2 步，共 2 步',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.only(right: EatSpace.s14),
              child: Text(
                '2 / 2',
                style: eat.text.meta.copyWith(color: palette.foreground),
              ),
            ),
          ),
      ],
    );
  }
}

/// 加菜页舞台内容.
///
/// - 右侧: 封面盘子. 没有照片时显示虚线圆 "加一张照片".
/// - 左下: 按已填写的分类, 菜名和价格预览这道菜在舞台上的样子.
class _StageContent extends StatelessWidget {
  const new({
    required this.cover,
    required this.crop,
    required this.sampled,
    required this.category,
    required this.name,
    required this.price,
    required this.onAdd,
    required this.onCover,
    required this.coverLabel,
  });

  /// 封面. 没有照片时为 null.
  final ImageProvider? cover;
  final CoverCrop crop;

  /// 舞台色是否取自 [cover]. 编辑时不换照片, 舞台色是这道菜现有的颜色, 不显示 "主色取自照片".
  final bool sampled;
  final DishCategory? category;
  final String name;
  final double? price;
  final VoidCallback onAdd;

  /// 点击封面盘子. 新照片打开 "调整照片", 编辑时的原有照片开始换照片.
  final VoidCallback onCover;
  final String coverLabel;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final cover = this.cover;
    final lines = name.isEmpty ? const <String>[] : DishRules.stageLines(name);
    final priceText = DishRules.priceText(price);
    return LayoutBuilder(
      builder: (context, constraints) {
        final plate = layout.isWide
            ? (constraints.maxHeight * 0.45).clamp(220.0, 420.0)
            : 236 * scale;
        final center = layout.isWide
            ? Offset(constraints.maxWidth / 2, constraints.maxHeight / 2)
            : Offset(constraints.maxWidth - plate / 2 - 8, 200 * scale);
        return Stack(
          children: [
            Positioned(
              left: center.dx - plate / 2,
              top: center.dy - plate / 2,
              child: cover == null
                  ? _AddPlate(size: plate, onTap: onAdd)
                  : EatTappable(
                      onTap: onCover,
                      label: coverLabel,
                      focusShape: const CircleBorder(),
                      builder: (context, _) => DishPlate(
                        image: cover,
                        size: plate,
                        centerX: crop.centerX,
                        centerY: crop.centerY,
                        diameter: crop.diameter,
                      ),
                    ),
            ),
            if (cover != null && sampled)
              Positioned(
                left: center.dx - plate / 2,
                width: plate,
                top: center.dy + plate / 2 + 14,
                child: Text(
                  '主色取自照片',
                  textAlign: TextAlign.center,
                  style: eat.text.caption.copyWith(
                    color: palette.secondaryForeground,
                  ),
                ),
              ),
            Positioned(
              left: EatSpace.s20,
              bottom: EatSize.sheetOverlap + 24,
              child: IgnorePointer(
                child: SizedBox(
                  width: 180 * layout.stageTextScale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category case final category?)
                        Text(
                          category.label,
                          style: eat.text.meta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: palette.secondaryForeground,
                          ),
                        ),
                      if (lines.isNotEmpty)
                        Text(
                          lines.join('\n'),
                          textScaler: TextScaler.noScaling,
                          style: eat.text.stage.copyWith(
                            fontSize:
                                (lines.length >= 3 ? 30.0 : 36.0) *
                                layout.stageTextScale,
                            height: 1.12,
                            color: palette.foreground,
                          ),
                        ),
                      if (priceText != null)
                        Text(
                          priceText,
                          textScaler: TextScaler.noScaling,
                          style: eat.text.priceHero.copyWith(
                            fontSize: 36 * layout.stageTextScale,
                            color: palette.foreground,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 没有照片时占据盘子位置的虚线圆 "加一张照片".
class _AddPlate extends StatelessWidget {
  const new({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    return EatTappable(
      onTap: onTap,
      label: '加一张照片',
      focusShape: const CircleBorder(),
      builder: (context, _) => Surface(
        style: SurfaceStyle.dashed(palette.foreground, width: 2),
        shape: const CircleBorder(),
        child: SizedBox.square(
          dimension: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: EatSpace.s8,
            children: [
              EatIcon(EatIcons.camera, size: 32, color: palette.foreground),
              Text(
                '加一张照片',
                style: eat.text.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 照片条: 已添加的照片, 添加按钮和张数.
///
/// 第一张是封面. 每张照片显示上传进度.
class _PhotoStrip extends StatelessWidget {
  const new({required this.photos, required this.onAdd, required this.onTap});

  final List<DraftPhoto> photos;
  final VoidCallback onAdd;
  final void Function(DraftPhoto photo, {required bool cover}) onTap;

  static const _size = 64.0;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final full = photos.length >= PublishRules.photosMax;
    return SizedBox(
      height: _size + 4,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (i, photo) in photos.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: EatSpace.s8),
                    child: _PhotoThumb(
                      photo: photo,
                      cover: i == 0,
                      size: _size,
                      onTap: () => onTap(photo, cover: i == 0),
                    ),
                  ),
                if (!full)
                  EatTappable(
                    onTap: onAdd,
                    label: '再加一张照片',
                    focusShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(EatRadius.thumbLg),
                    ),
                    builder: (context, _) => Surface(
                      style: SurfaceStyle.dashed(c.lineStrong),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(EatRadius.thumbLg),
                      ),
                      child: SizedBox.square(
                        dimension: _size,
                        child: Center(
                          child: EatIcon(EatIcons.add, size: 22, color: c.ink),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: EatSpace.s10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${photos.length}',
                  style: eat.text.priceInline.copyWith(color: c.ink),
                ),
                TextSpan(
                  text: ' / ${PublishRules.photosMax}',
                  style: eat.text.meta.copyWith(color: c.inkMuted),
                ),
              ],
            ),
            semanticsLabel:
                '已加 ${photos.length} 张，最多 ${PublishRules.photosMax} 张',
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const new({
    required this.photo,
    required this.cover,
    required this.size,
    required this.onTap,
  });

  final DraftPhoto photo;
  final bool cover;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final status = switch (photo.status) {
      UploadStatus.waiting => '等待上传',
      UploadStatus.uploading => '上传中 ${(photo.progress * 100).round()}%',
      UploadStatus.done => '已上传',
      UploadStatus.failed => '上传失败',
    };
    final overlay = switch (photo.status) {
      UploadStatus.done => null,
      UploadStatus.failed => EatIcon(
        EatIcons.warning,
        size: 22,
        color: c.paper,
      ),
      UploadStatus.waiting => null,
      UploadStatus.uploading => Text(
        '${(photo.progress * 100).round()}%',
        style: eat.text.count.copyWith(color: c.paper),
      ),
    };
    return EatTappable(
      onTap: onTap,
      label: '${cover ? '封面，' : ''}$status',
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumbLg),
      ),
      builder: (context, _) => ClipRRect(
        borderRadius: const BorderRadius.all(EatRadius.thumbLg),
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: photo.image,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                gaplessPlayback: true,
              ),
              if (photo.status != UploadStatus.done)
                ColoredBox(
                  color: photo.status == UploadStatus.failed
                      ? c.warn.withValues(alpha: 0.7)
                      : c.ink.withValues(alpha: 0.45),
                  child: Center(child: overlay),
                ),
              if (cover) const _CoverBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 缩略图底部的 "封面" 字样.
class _CoverBadge extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ColoredBox(
        color: c.ink.withValues(alpha: 0.6),
        child: Text(
          '封面',
          textAlign: TextAlign.center,
          style: eat.text.caption.copyWith(color: c.paper),
        ),
      ),
    );
  }
}

// TODO: 菜品响应只有图片地址, 没有存储 key, 编辑时无法提交保留的原图, 照片只能整组更换. 后端在响应中提供 key 后改为可以单张增删和调整原有照片.
/// 编辑时的原有照片和 "换照片".
///
/// 原有照片只能看, 不能单张删除或调整. 选了新照片后整组替换原有照片.
class _ExistingPhotos extends StatelessWidget {
  const new({required this.images, required this.onReplace});

  final List<String> images;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    const size = _PhotoStrip._size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        SizedBox(
          height: size + 4,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (i, url) in images.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: EatSpace.s8),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            EatRadius.thumbLg,
                          ),
                          child: SizedBox.square(
                            dimension: size,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CoverImage(
                                  image: networkImage(url, width: size),
                                ),
                                if (i == 0) const _CoverBadge(),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: EatSpace.s10),
              EatButton.outline(
                images.isEmpty ? '加照片' : '换照片',
                height: 36,
                onPressed: onReplace,
              ),
            ],
          ),
        ),
        if (images.isNotEmpty)
          Text(
            '换照片会替换现有的全部照片',
            style: eat.text.caption.copyWith(color: eat.colors.inkMuted),
          ),
      ],
    );
  }
}

/// 编辑时已选了新照片: 说明原有照片会被替换, 以及 "不换了".
class _ReplacingNote extends StatelessWidget {
  const new({required this.count, required this.onUndo});

  /// 原有照片的张数.
  final int count;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == 0 ? '保存后加上这些照片' : '保存后替换原有的 $count 张照片',
              style: eat.text.caption.copyWith(color: eat.colors.inkMuted),
            ),
          ),
          EatButton.outline('不换了', height: 36, onPressed: onUndo),
        ],
      ),
    );
  }
}

/// 这道菜所在的店. 发布新菜时可以 "换一家", 编辑时不能换店.
class _ShopLine extends StatelessWidget {
  const new({required this.name, required this.onChange});

  /// 店名. 读取中为 null.
  final String? name;

  /// 换店. 为 null 时不显示 "换一家".
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final onChange = this.onChange;
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: onChange == null ? '所在的店 ' : '发布到 '),
                TextSpan(
                  text: name ?? '…',
                  style: eat.text.subhead.copyWith(color: c.ink),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: eat.text.body.copyWith(color: c.inkSoft),
          ),
        ),
        if (onChange != null)
          EatButton.outline('换一家', height: 36, onPressed: onChange),
      ],
    );
  }
}

/// 重名提示和 "去看看".
///
/// 同一家店内菜名重复时不能发布, 提示引导用户查看已有的菜.
class _DuplicateNotice extends StatelessWidget {
  const new({required this.name, required this.onOpen});

  final String name;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '这家店已有「$name」',
                style: eat.text.meta.copyWith(color: eat.colors.warn),
              ),
            ),
            EatButton.outline('去看看', height: 36, onPressed: onOpen),
          ],
        ),
      ),
    );
  }
}

/// 抽屉中的一组字段: 小标题和内容. [note] 是小标题右侧的一行说明.
class _Group extends StatelessWidget {
  const new({required this.title, this.note, required this.child});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final style = eat.text.meta.copyWith(color: eat.colors.inkMuted);
    return Padding(
      padding: const EdgeInsets.only(bottom: EatSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          Row(
            spacing: EatSpace.s8,
            children: [
              Semantics(header: true, child: Text(title, style: style)),
              if (note case final note?)
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      note,
                      textAlign: TextAlign.end,
                      style: eat.text.caption.copyWith(
                        color: eat.colors.inkMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

// TODO: 后端 v2 没有我的标签接口, "自己写" 只保留入口. 接口上线后恢复输入我的标签并随发布提交, 去掉 "待接入".
/// 口味选择: 5 个口味多选, 最多 [PublishRules.tagsMax] 个.
///
/// "自己写" 是我的标签的入口, 标 "待接入", 点击不发请求.
class _Tastes extends StatelessWidget {
  const new({required this.selected, required this.onToggle});

  final Set<Taste> selected;
  final ValueChanged<Taste> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: EatSpace.s8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final taste in Taste.values)
        EatChip.tag(
          taste.label,
          selected: selected.contains(taste),
          onTap: () => onToggle(taste),
        ),
      EatChip.add(
        '自己写',
        onTap: () => showPending(context, PendingFeature.myTags),
      ),
      const PendingTag(),
    ],
  );
}

/// "招牌菜" 开关. 招牌菜已满时 ([full]) 在开关下提示.
class _Signature extends StatelessWidget {
  const new({required this.value, required this.full, required this.onChanged});

  final bool value;
  final bool full;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EatSwitch(
          label: '招牌菜',
          description: '每家店最多 3 道招牌菜',
          value: value,
          onChanged: onChanged,
        ),
        if (full)
          Semantics(
            liveRegion: true,
            child: Text(
              _signatureFullText,
              style: eat.text.meta.copyWith(color: eat.colors.warn),
            ),
          ),
      ],
    );
  }
}

/// "说两句" 输入框. 多行输入, 右下角显示字数.
class _NoteField extends StatelessWidget {
  const new({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: c.mist,
        borderRadius: const BorderRadius.all(EatRadius.thumb),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 6,
              onChanged: (_) => onChanged(),
              inputFormatters: const [
                CodePointLengthLimitingFormatter(PublishRules.noteMax),
              ],
              style: eat.text.body.copyWith(color: c.ink),
              cursorColor: c.ink,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '好吃在哪，有什么要注意的',
                hintStyle: eat.text.body.copyWith(color: c.inkMuted),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Text(
              '${codePointLength(controller.text)} / ${PublishRules.noteMax}',
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
