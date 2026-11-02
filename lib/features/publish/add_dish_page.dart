import 'dart:async';

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
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/surface.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
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
import 'package:eat/state/shops.dart';
import 'package:eat/state/taste_vocabulary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 发布流程第 2 步: 加菜.
///
/// - 舞台: 封面和封面的舞台色.
/// - 抽屉: 照片, 店, 菜名, 价格, 分类, 饭点, 标签和 "说两句".
///
/// 照片添加后立即在后台上传. 添加第一张照片后自动打开 "调整照片".
/// 已填写内容时返回需要确认. 草稿不保存.
/// 发布成功后关闭发布流程的所有页面, 再打开新发布的菜.
class AddDishPage extends ConsumerStatefulWidget {
  const new({super.key, required this.shopId});

  final int shopId;

  @override
  ConsumerState<AddDishPage> createState() => _AddDishPageState();
}

class _AddDishPageState extends ConsumerState<AddDishPage> {
  late int _shopId = widget.shopId;

  /// 通过 "换一家" 选中的店. 不为 null 时直接使用, 不再请求店铺资料.
  Shop? _changedShop;
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  final _myTag = TextEditingController();
  var _writingTag = false;
  var _busy = false;

  /// 发布时服务端判定重名, 返回的已有菜品 id.
  int? _duplicateId;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(draftProvider.notifier).retryFailedOnce(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _name.dispose();
    _price.dispose();
    _note.dispose();
    _myTag.dispose();
    super.dispose();
  }

  bool get _dirty =>
      ref.read(draftProvider).photos.isNotEmpty ||
      _name.text.trim().isNotEmpty ||
      _price.text.trim().isNotEmpty ||
      _note.text.trim().isNotEmpty;

  Future<void> _leave() async {
    if (_dirty && !await _confirmLeave()) return;
    if (mounted) BackFallback.back(context);
  }

  Future<bool> _confirmLeave() async =>
      await showPanel<bool>(
        context,
        builder: (panel) => EatPanel(
          icon: EatIcons.warning,
          title: '这道菜还未发布，确定放弃吗？',
          actions: Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '放弃',
                  onPressed: () => Navigator.of(panel).pop(true),
                ),
              ),
              Expanded(
                child: EatButton.solid(
                  '继续编辑',
                  onPressed: () => Navigator.of(panel).pop(false),
                ),
              ),
            ],
          ),
        ),
      ) ??
      false;

  Future<void> _addPhotos() async {
    final draft = ref.read(draftProvider);
    final room = PublishRules.photosMax - draft.photos.length;
    if (room <= 0) return;
    final photos = await pickPhotos(context, ref, limit: room);
    if (!mounted || photos.isEmpty) return;
    final first = ref.read(draftProvider.notifier).addPhotos(photos);
    if (first) await _crop();
  }

  /// 打开 "调整照片" 调整封面.
  Future<void> _crop() async {
    final notifier = ref.read(draftProvider.notifier);
    final draft = ref.read(draftProvider);
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
    final notifier = ref.read(draftProvider.notifier);
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
    final draft = ref.read(draftProvider);
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
      mealTimes: [
        for (final meal in MealTime.values)
          if (draft.meals.contains(meal)) meal,
      ],
      stage: draft.stage,
      stageAlternates: draft.alternates,
      crop: draft.crop,
      tasteTagIds: draft.tasteTagIds.toList(),
      myTagNames: draft.myTags,
      description: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    try {
      final result = await ref.read(foodRepositoryProvider).publish(dish);
      ref.read(publishedCountProvider.notifier).published();
      if (mounted) _finish(result);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.code == BizCodes.duplicateDish) {
        final data = e.data;
        final id = data is Map ? data['id'] : null;
        setState(() => _duplicateId = id is num ? id.toInt() : null);
        showToast(context, e.message);
        return;
      }
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.publishDish,
        fallback: '发布失败，请重试',
      );
    }
  }

  /// 关闭发布流程的所有页面, 再压入新发布的菜.
  ///
  /// - 先关闭再压入, 用户从菜品详情返回时回到发起发布的页面, 而不是回到发布流程.
  /// - 菜品进入审核时不打开详情: 审核通过前详情接口返回菜品不存在.
  ///   没有发起页面 (发布流程是第一个页面) 时回到发现页.
  ///
  /// 轻提示在离开页面前显示. 提示插入根 Overlay, 页面关闭后继续显示.
  /// 根 Navigator 自身的 context 位于其 Overlay 之上, 以该 context 查找 Overlay 会失败, 提示不显示.
  void _finish(PublishResult result) {
    showToast(context, result.pending ? '已提交审核，通过后公开' : '发布成功');
    final router = GoRouter.of(context);
    while (router.canPop() &&
        router.state.matchedLocation.startsWith(Paths.publish)) {
      router.pop();
    }
    final stillPublishing = router.state.matchedLocation.startsWith(
      Paths.publish,
    );
    if (result.pending) {
      if (stillPublishing) router.go(Paths.discover);
      return;
    }
    if (stillPublishing) {
      router.go(Paths.dish(result.id));
    } else {
      unawaited(router.push(Paths.dish(result.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftProvider);
    final shop = _changedShop ?? ref.watch(shopProvider(_shopId)).value;
    final name = _name.text.trim();
    final price = PublishRules.parsePrice(_price.text);
    final sameName = ref.watch(sameNameDishProvider(_shopId, name)).value;
    final duplicateId = sameName?.id ?? _duplicateId;
    final missing = PublishRules.missingText(
      photo: draft.photos.isNotEmpty,
      name: name.isNotEmpty,
      price: price != null,
      category: draft.category != null,
      meal: draft.meals.isNotEmpty,
    );
    final media = MediaQuery.of(context);

    final String? note;
    final String label;
    VoidCallback? onPressed = _publish;
    if (missing != null) {
      note = missing;
      label = '发布';
      onPressed = null;
    } else if (duplicateId != null) {
      note = '这家店已有这道菜，去看看再说两句';
      label = '发布';
      onPressed = null;
    } else if (draft.hasFailedUpload) {
      note = '有照片未上传成功，点照片重试或删除';
      label = '发布';
      onPressed = null;
    } else if (draft.uploading) {
      note = null;
      label = '照片上传中 ${(draft.uploadProgress * 100).round()}%';
      onPressed = null;
    } else {
      note = null;
      label = '发布';
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
                    stage: draft.stage,
                    topBar: _TopBar(onBack: _leave),
                    stageContent: _StageContent(
                      draft: draft,
                      name: name,
                      price: price,
                      onAdd: _addPhotos,
                      onCrop: _crop,
                    ),
                    sheetSlivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EatSpace.s20,
                        ),
                        sliver: SliverList.list(
                          children: [
                            _PhotoStrip(
                              photos: draft.photos,
                              onAdd: _addPhotos,
                              onTap: _photoActions,
                            ),
                            const SizedBox(height: EatSpace.s16),
                            _ShopLine(shop: shop, onChange: _changeShop),
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
                              onChanged: (_) =>
                                  setState(() => _duplicateId = null),
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
                              errorText: PublishRules.priceError(_price.text),
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: EatSpace.s24),
                            _Group(
                              title: '分类',
                              child: Wrap(
                                spacing: EatSpace.s8,
                                children: [
                                  for (final c in DishCategory.values)
                                    EatChip.choice(
                                      c.label,
                                      selected: draft.category == c,
                                      onTap: () => ref
                                          .read(draftProvider.notifier)
                                          .setCategory(c),
                                    ),
                                ],
                              ),
                            ),
                            _Group(
                              title: '适合哪顿，可以多选',
                              child: Wrap(
                                spacing: EatSpace.s8,
                                children: [
                                  for (final meal in MealTime.values)
                                    EatChip.tag(
                                      meal.label,
                                      selected: draft.meals.contains(meal),
                                      onTap: () => ref
                                          .read(draftProvider.notifier)
                                          .toggleMeal(meal),
                                    ),
                                ],
                              ),
                            ),
                            _Group(
                              title: '标签，可以多选',
                              child: _Tags(
                                draft: draft,
                                writing: _writingTag,
                                input: _myTag,
                                onWrite: () =>
                                    setState(() => _writingTag = true),
                              ),
                            ),
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

class _TopBar extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    return Row(
      children: [
        EatBackButton(onPressed: onBack),
        const Spacer(),
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
/// - 右侧: 封面盘子, 点击打开 "调整照片". 没有照片时显示虚线圆 "加一张照片".
/// - 左下: 按已填写的分类, 菜名和价格预览这道菜在舞台上的样子.
class _StageContent extends StatelessWidget {
  const new({
    required this.draft,
    required this.name,
    required this.price,
    required this.onAdd,
    required this.onCrop,
  });

  final PublishDraft draft;
  final String name;
  final double? price;
  final VoidCallback onAdd;
  final VoidCallback onCrop;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final cover = draft.photos.firstOrNull;
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
                      onTap: onCrop,
                      label: '调整照片',
                      focusShape: const CircleBorder(),
                      builder: (context, _) => DishPlate(
                        image: cover.image,
                        size: plate,
                        centerX: draft.crop.centerX,
                        centerY: draft.crop.centerY,
                        diameter: draft.crop.diameter,
                      ),
                    ),
            ),
            if (cover != null)
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
                      if (draft.category case final category?)
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
                          style: eat.text.stageDish.copyWith(
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
        style: eat.text.priceInline.copyWith(fontSize: 13, color: c.paper),
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
              if (cover)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: c.ink.withValues(alpha: 0.6),
                    child: Text(
                      '封面',
                      textAlign: TextAlign.center,
                      style: eat.text.caption.copyWith(
                        fontSize: 11,
                        color: c.paper,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 发布到哪家店, 以及 "换一家".
class _ShopLine extends StatelessWidget {
  const new({required this.shop, required this.onChange});

  final Shop? shop;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '发布到 '),
                TextSpan(
                  text: shop?.name ?? '…',
                  style: eat.text.rowTitle.copyWith(color: c.ink),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: eat.text.body.copyWith(color: c.inkSoft),
          ),
        ),
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
                '这家店已有$name',
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

/// 抽屉中的一组字段: 小标题和内容.
class _Group extends StatelessWidget {
  const new({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Padding(
      padding: const EdgeInsets.only(bottom: EatSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// 标签选择.
///
/// - 口味词表中的标签可多选.
/// - "+ 自己写" 添加的是我的标签. 输入时说明我的标签只有自己可见.
class _Tags extends ConsumerWidget {
  const new({
    required this.draft,
    required this.writing,
    required this.input,
    required this.onWrite,
  });

  final PublishDraft draft;
  final bool writing;
  final TextEditingController input;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final notifier = ref.read(draftProvider.notifier);
    final vocabulary = ref.watch(tasteVocabularyProvider);
    void add() {
      notifier.addMyTag(input.text);
      input.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: EatSpace.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...switch (vocabulary) {
              AsyncData(:final value) => [
                for (final tag in value)
                  EatChip.tag(
                    tag.name,
                    selected: draft.tasteTagIds.contains(tag.id),
                    onTap: () => notifier.toggleTaste(tag.id),
                  ),
              ],
              AsyncError() => [
                EatChip.add(
                  '口味词加载失败，重试',
                  onTap: () => ref.invalidate(tasteVocabularyProvider),
                ),
              ],
              _ => const [SizedBox(width: 120, child: Skeleton(height: 36))],
            },
            for (final name in draft.myTags)
              EatChip.tag(
                name,
                selected: true,
                onTap: () => notifier.removeMyTag(name),
              ),
            if (!writing) EatChip.add('＋ 自己写', onTap: onWrite),
          ],
        ),
        if (writing) ...[
          EatFormField(
            label: '自己写一个标签',
            controller: input,
            autofocus: true,
            hintText: '比如 考试周',
            textInputAction: TextInputAction.done,
            inputFormatters: const [
              CodePointLengthLimitingFormatter(PublishRules.myTagMax),
            ],
            onSubmitted: (_) => add(),
            trailing: EatButton.outline('加上', height: 36, onPressed: add),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '自己写的标签只有你自己看得见',
              style: eat.text.caption.copyWith(color: eat.colors.inkMuted),
            ),
          ),
        ],
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
