import 'package:eat/core/failure/app_failure.dart';
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

// TODO: 反馈接口暂不支持接收版本号, 补丁号与设备型号, 页面目前仅作展示以供用户自行填写. 后端补充对应字段后改为随反馈请求一并提交.
/// 问题反馈与建议提交页面, 要求填写最多 500 字的反馈正文并支持选填最多 3 张截图.
///
/// - 从菜品详情或店铺详情进入时, 顶部显示对应主题名称并在提交时关联该菜品或店铺 id.
/// - 提交成功后提示处理结果将通过消息通知并自动返回上一页; 失败重试时已上传的截图不会重复上传.
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

  /// 缓存已上传截图对应的存储 key, 避免失败重试时重复上传.
  final _uploaded = <Uint8List, String>{};

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
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
        setState(() => _shots.addAll(picked));
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
    final counter = eat.text.count.copyWith(color: c.inkMuted);
    final length = _text.text.trim().runes.length;
    final sending = ref.watch(feedbackSenderProvider);
    return PlainScaffold(
      title: '反馈',
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
                      style: eat.text.subhead.copyWith(color: c.ink),
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
              hintText: '遇到的问题、改进建议，或对处理结果的疑问',
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
                    onRemove: () => setState(() => _shots.removeAt(i)),
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
                  const TextSpan(text: '，反馈问题时附上设备型号，方便我们更快排查'),
                ],
              ),
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: EatSpace.s14),
            EatButton.solid(
              '提交',
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

/// 单张已选截图的缩略图预览组件, 右上角附带移除按钮.
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
