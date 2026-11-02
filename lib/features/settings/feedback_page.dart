import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/platform/hot_update.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 反馈接口不接收版本, 补丁号和设备型号, 页面只展示版本和补丁号, 由用户自行写入反馈. 后端增加这些字段后随反馈一起提交.
/// 反馈: 文字必填, 最多 500 字. 截图选填, 最多 3 张.
///
/// - 从菜品详情或餐厅详情进入时, 顶部显示 "关于 某某", 提交时附带该菜或店.
/// - 提交成功后提示处理结果会通过消息通知, 并返回上一页.
/// - 内容不变时重试沿用同一个幂等键, 已上传的截图不重复上传.
class FeedbackPage extends ConsumerStatefulWidget {
  const new({super.key, this.dishId, this.shopId});

  final int? dishId;
  final int? shopId;

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  static const _maxLength = 500;
  static const _maxShots = 3;

  final _text = TextEditingController();
  final _shots = <PickedPhoto>[];

  /// 已上传的截图的 key. 重试时不重复上传.
  final _uploaded = <Uint8List, String>{};

  /// 本次内容的幂等键. 文字或截图变化时生成新键.
  var _idempotencyKey = newIdempotencyKey();
  String _keyedText = '';

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      if (_text.text != _keyedText) _renewKey();
      setState(() {});
    });
  }

  void _renewKey() {
    _keyedText = _text.text;
    _idempotencyKey = newIdempotencyKey();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    try {
      await ref
          .read(feedbackSenderProvider.notifier)
          .send(
            text: _text.text,
            screenshots: [for (final shot in _shots) shot.bytes],
            uploaded: _uploaded,
            dishId: widget.dishId,
            shopId: widget.shopId,
            idempotencyKey: _idempotencyKey,
          );
      if (!mounted) return;
      showToast(context, '已提交，处理结果会通过消息通知你');
      BackFallback.back(context);
    } on AppFailure catch (e) {
      if (mounted && e.kind != FailureKind.cancelled) {
        showToast(
          context,
          e.kind == FailureKind.unknown ? '提交失败，请重试' : e.message,
        );
      }
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addShots() async {
    try {
      final picked = await ref
          .read(photoPickerProvider)
          .pickFromGallery(limit: _maxShots - _shots.length);
      if (mounted && picked.isNotEmpty) {
        setState(() {
          _shots.addAll(picked);
          _renewKey();
        });
      }
    } on PhotoPickException catch (e) {
      if (mounted) {
        showToast(context, switch (e.reason) {
          PhotoPickFailure.denied => '请在系统设置中允许访问相册',
          PhotoPickFailure.unsupported => '不支持该图片格式，请更换',
        });
      }
    } on Object {
      if (mounted) showToast(context, '图片读取失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final subject = ref
        .watch(
          feedbackSubjectProvider(dishId: widget.dishId, shopId: widget.shopId),
        )
        .value;
    final version = ref.watch(appVersionProvider).value;
    final patch = ref.watch(currentPatchProvider).value;
    final counter = eat.text.count.copyWith(fontSize: 13, color: c.inkMuted);
    final length = _text.text.trim().runes.length;
    final sending = ref.watch(feedbackSenderProvider);
    return PlainScaffold(
      title: '反馈',
      subtitle: '出问题、提建议、觉得被误伤了，都可以说',
      slivers: [
        SliverList.list(
          children: [
            if (subject != null) ...[
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '关于 '),
                    TextSpan(
                      text: subject,
                      style: eat.text.rowTitle.copyWith(color: c.ink),
                    ),
                  ],
                ),
                style: eat.text.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: EatSpace.s14),
            ],
            EatFormField.multiline(
              label: '反馈内容',
              controller: _text,
              hintText: '说说遇到了什么问题，或者希望怎么改',
              inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$length', style: counter),
                    TextSpan(text: ' / $_maxLength', style: counter),
                  ],
                ),
              ),
            ),
            const SizedBox(height: EatSpace.s20),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '截图，选填，最多 3 张  '),
                  TextSpan(text: '${_shots.length}', style: counter),
                  TextSpan(text: ' / $_maxShots', style: counter),
                ],
              ),
              style: eat.text.meta.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: EatSpace.s10),
            Wrap(
              spacing: EatSpace.s10,
              runSpacing: EatSpace.s10,
              children: [
                for (final (i, shot) in _shots.indexed)
                  _Shot(
                    image: MemoryImage(shot.bytes),
                    onRemove: () => setState(() {
                      _shots.removeAt(i);
                      _renewKey();
                    }),
                  ),
                if (_shots.length < _maxShots)
                  EatTappable(
                    onTap: _addShots,
                    label: '添加截图',
                    focusShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(EatRadius.thumb),
                    ),
                    builder: (context, _) => Container(
                      width: EatSize.thumbLg,
                      height: EatSize.thumbLg,
                      decoration: BoxDecoration(
                        color: c.mist,
                        borderRadius: const BorderRadius.all(EatRadius.thumb),
                      ),
                      child: Center(
                        child: EatIcon(EatIcons.add, size: 24, color: c.ink),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '现在的版本是 '),
                  TextSpan(text: version ?? '–', style: eat.text.count),
                  if (patch != null) ...[
                    const TextSpan(text: '、补丁 '),
                    TextSpan(text: '$patch', style: eat.text.count),
                  ],
                  const TextSpan(text: '，说问题时写上手机型号，我们查得更快'),
                ],
              ),
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: EatSpace.s14),
            EatButton.solid(
              length == 0 ? '写几句再提交' : '提交',
              loading: sending,
              onPressed: length == 0 ? null : _submit,
            ),
            const SizedBox(height: EatSpace.s24),
          ],
        ),
      ],
    );
  }
}

/// 一张已选的截图, 右上角可以移除.
class _Shot extends StatelessWidget {
  const new({required this.image, required this.onRemove});

  final ImageProvider image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return SizedBox(
      width: EatSize.thumbLg,
      height: EatSize.thumbLg,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(EatRadius.thumb),
              child: Image(image: image, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: -14,
            top: -14,
            child: EatIconButton(
              EatIcons.closeCircle,
              label: '移除截图',
              size: 20,
              color: c.ink,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}
