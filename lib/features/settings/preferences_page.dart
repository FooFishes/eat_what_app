import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
import 'package:eat/design/widgets/eat_segment_slider.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/recommend_preferences.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/settings/preferences_providers.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/settings/widgets/settings_group.dart';
import 'package:eat/features/system/guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 推荐偏好页: 喜欢的品类和口味, 忌口, 价位和最远距离, 以及服务端推断出的偏爱 (只读).
///
/// - 改动先存在页面里, 点右上角 "保存" 才整体提交; 有改动时返回会确认是否放弃.
/// - 个性化推荐关闭时偏好不参与推荐, 页面照常可改, 顶部说明暂不生效.
/// - "清空偏好" 确认后删除服务端保存的全部偏好.
class PreferencesPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  /// 页面上的改动, 为 null 时表示沿用服务端保存的偏好.
  RecommendPreferences? _draft;
  var _saving = false;

  /// 已保存或已确认放弃, 返回时不再拦截.
  var _leaving = false;

  RecommendPreferences? get _saved =>
      ref.read(recommendPreferencesSettingProvider).value?.saved;

  bool get _dirty {
    final draft = _draft;
    return draft != null && draft != _saved;
  }

  void _edit(RecommendPreferences Function(RecommendPreferences) change) {
    final current = _draft ?? _saved;
    if (current == null || _saving) return;
    setState(() => _draft = change(current));
  }

  Future<void> _save() async {
    final draft = _draft;
    if (_saving) return;
    if (draft == null || !_dirty) {
      BackFallback.back(context);
      return;
    }
    if (!await guardAction(context, ref, Capability.changePrivacy)) return;
    setState(() => _saving = true);
    try {
      await ref.read(recommendPreferencesSettingProvider.notifier).save(draft);
      if (!mounted) return;
      showToast(context, '偏好已保存');
      _leave();
    } on AppFailure catch (e) {
      if (!mounted) return;
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.changePrivacy,
        fallback: '保存失败，请重试',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    if (_saving) return;
    final confirmed = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        title: '清空推荐偏好？',
        subtitle: '喜欢的品类和口味、忌口、价位和最远距离都会清空，推荐不再参考这些设置。',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '先不清空',
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '清空',
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!await guardAction(context, ref, Capability.changePrivacy)) return;
    setState(() => _saving = true);
    try {
      await ref.read(recommendPreferencesSettingProvider.notifier).clear();
      if (!mounted) return;
      setState(() => _draft = null);
      showToast(context, '偏好已清空');
    } on AppFailure catch (e) {
      if (!mounted) return;
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.changePrivacy,
        fallback: '清空失败，请重试',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 处理返回操作: 保存过程中禁止返回, 有改动时需先确认是否放弃.
  Future<void> _back() async {
    if (_saving) return;
    if (_dirty && !await _confirmDiscard()) return;
    if (mounted) _leave();
  }

  /// 解除返回拦截后离开页面. 拦截在下一帧重建后才解除, 因此在该帧结束后返回.
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
          subtitle: '这次改过的偏好不会保存。',
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

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final data = ref.watch(recommendPreferencesSettingProvider);
    final personalized = ref.watch(personalizedProvider).value;
    final loaded = data.value;
    final List<Widget> body;
    if (loaded != null) {
      body = _form(loaded, personalized: personalized != false);
    } else if (data.hasError && !data.isLoading) {
      body = [
        const SizedBox(height: EatSpace.s24),
        FailureState(
          error: data.error,
          onRetry: () => ref.invalidate(recommendPreferencesSettingProvider),
        ),
      ];
    } else {
      body = const [SizedBox(height: EatSpace.s10), _FormPlaceholder()];
    }
    return PopScope(
      canPop: _leaving || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: PlainScaffold(
        title: '推荐偏好',
        onBack: _back,
        actions: [
          if (loaded != null)
            EatTappable(
              onTap: _saving ? null : _save,
              label: '保存',
              builder: (context, _) => SizedBox(
                height: EatSize.touch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      _saving ? '保存中' : '保存',
                      style: eat.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _saving ? c.disabledFg : c.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        slivers: [SliverList.list(children: body)],
      ),
    );
  }

  List<Widget> _form(PreferencesData data, {required bool personalized}) {
    final eat = context.eat;
    final c = eat.colors;
    final p = _draft ?? data.saved;
    final options = data.options;
    final note = eat.text.meta.copyWith(color: c.inkMuted);
    Widget chips(List<Widget> children) =>
        Wrap(spacing: EatSpace.s8, runSpacing: EatSpace.s8, children: children);
    // "不限" 放在最右边: 价位和距离都是越往右越宽松.
    final bands = <PriceBand?>[...PriceBand.values, null];
    final distances = <int?>[
      ...[
        ...RecommendPreferences.distanceChoices,
        if (p.maxDistance case final d?
            when !RecommendPreferences.distanceChoices.contains(d))
          d,
      ]..sort(),
      null,
    ];
    return [
      if (!personalized)
        Padding(
          padding: const EdgeInsets.only(top: EatSpace.s10, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EatSpace.s8,
            children: [
              EatIcon(EatIcons.warning, size: 18, color: c.warn),
              Expanded(
                child: Text(
                  '个性化推荐已关闭，偏好暂不生效。在隐私设置里打开后生效',
                  style: eat.text.meta.copyWith(color: c.warn),
                ),
              ),
            ],
          ),
        )
      else if (data.saved.isEmpty && _draft == null)
        Padding(
          padding: const EdgeInsets.only(top: EatSpace.s10, left: 4),
          child: Text('还没设置偏好。选几项喜欢的，推荐会更合你的口味', style: note),
        ),
      const SizedBox(height: EatSpace.s20),
      SettingsGroup(
        title: '喜欢的',
        note: const Text('推荐时优先'),
        dividerIndent: 0,
        children: [
          _Field(
            label: '品类',
            child: chips([
              for (final category in options.categories)
                EatChip.tag(
                  category.label,
                  selected: p.likedCategories.contains(category),
                  onTap: () => _edit((p) => p.toggleCategory(category)),
                ),
            ]),
          ),
          _Field(
            label: '口味',
            child: chips([
              for (final taste in options.tastes)
                EatChip.tag(
                  taste.label,
                  selected: p.likedTastes.contains(taste),
                  onTap: () => _edit((p) => p.toggleLiked(taste)),
                ),
            ]),
          ),
        ],
      ),
      const SizedBox(height: EatSpace.s24),
      SettingsGroup(
        title: '忌口',
        note: const Text('带这些口味的店不会推荐给你'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EatSpace.s14),
            child: chips([
              for (final taste in options.dislikable)
                EatChip.tag(
                  taste.label,
                  selected: p.dislikedTastes.contains(taste),
                  onTap: () => _edit((p) => p.toggleDisliked(taste)),
                ),
            ]),
          ),
        ],
      ),
      const SizedBox(height: EatSpace.s24),
      SettingsGroup(
        title: '价位和距离',
        dividerIndent: 0,
        children: [
          _Field(
            label: '人均价位',
            child: EatSegmentSlider.coins(
              semanticsLabel: '人均价位',
              allIndex: bands.length - 1,
              labels: [for (final band in bands) band?.label ?? '不限'],
              selected: bands.indexOf(p.priceBand),
              onChanged: (i) => _edit((p) => p.withPriceBand(bands[i])),
            ),
          ),
          _Field(
            label: '最远距离',
            hint: '只对去店里吃生效',
            child: EatSegmentSlider.route(
              semanticsLabel: '最远距离',
              icons: [for (final meters in distances) _travelIcon(meters)],
              labels: [
                for (final meters in distances)
                  meters == null
                      ? '不限'
                      : GeoRules.formatDistance(meters.toDouble()),
              ],
              selected: distances.indexOf(p.maxDistance),
              onChanged: (i) => _edit((p) => p.withMaxDistance(distances[i])),
            ),
          ),
        ],
      ),
      if (personalized) ...[
        const SizedBox(height: EatSpace.s24),
        const _TasteSection(),
      ],
      if (!data.saved.isEmpty) ...[
        const SizedBox(height: 28),
        EatButton.mist(
          '清空偏好',
          icon: EatIcons.delete,
          onPressed: _saving ? null : _clear,
        ),
      ],
      const SizedBox(height: EatSpace.s24),
    ];
  }
}

/// 最远距离对应的出行方式图标: 1 km 以内步行, 2 km 以内骑车, 再远和不限开车.
EatIcons _travelIcon(int? meters) => switch (meters) {
  final m? when m <= 1000 => EatIcons.walk,
  final m? when m <= 2000 => EatIcons.bike,
  _ => EatIcons.car,
};

/// 卡片里的一项: 上面一行是名字和可选的说明, 下面是选择控件.
class _Field extends StatelessWidget {
  const new({required this.label, this.hint, required this.child});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EatSpace.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EatSpace.s10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: EatSpace.s8,
            children: [
              Text(
                label,
                style: eat.text.body.copyWith(
                  color: c.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hint case final hint?)
                Expanded(
                  child: Text(
                    hint,
                    textAlign: TextAlign.end,
                    style: eat.text.meta.copyWith(color: c.inkMuted),
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

/// 服务端从点赞, 收藏和评价里推断出的偏爱, 只读展示.
class _TasteSection extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final taste = ref.watch(tasteProfileProvider);
    final note = eat.text.meta.copyWith(color: c.inkMuted);
    final Widget content;
    if (taste.value case final profile?) {
      final names = [
        for (final t in profile.inferredTastes) t.label,
        for (final category in profile.inferredCategories) category.label,
      ];
      content = profile.isEmpty
          ? Text('多赞几道菜、收藏几家店，这里会显示你偏爱的口味和品类', style: note)
          : Text(
              names.map((n) => '「$n」').join(''),
              style: eat.text.body.copyWith(color: c.ink),
            );
    } else if (taste.hasError && !taste.isLoading) {
      content = LoadFailureReport(
        error: taste.error,
        child: Row(
          spacing: EatSpace.s8,
          children: [
            Text('加载失败', style: note),
            EatButton.mist(
              '重试',
              height: 36,
              onPressed: () => ref.invalidate(tasteProfileProvider),
            ),
          ],
        ),
      );
    } else {
      content = const LoadingArea(child: Skeleton.line(width: 160));
    }
    return SettingsGroup(
      title: '从你的点赞和收藏看出',
      note: const Text('推荐时和你选的喜欢一起优先'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s14),
          child: content,
        ),
      ],
    );
  }
}

/// 偏好表单的加载占位, 按分组小标题和一张卡片排列.
class _FormPlaceholder extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => LoadingArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SizedBox(height: EatSpace.s20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Skeleton.line(width: 72, fontSize: 13),
          ),
          const SizedBox(height: EatSpace.s10),
          const Skeleton(height: 120, radius: EatRadius.thumbLg),
        ],
      ],
    ),
  );
}
