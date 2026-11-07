import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/current_user.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/profile_rules.dart';
import 'package:eat/features/profile/avatar_crop_page.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/profile/widgets/profile_stage.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Source { camera, gallery }

/// 编辑资料: 头像, 昵称 (2–12 个字) 和签名 (选填, 最多 30 个字).
///
/// - 换头像: 拍照或从相册选, 调整进圆圈后裁成 512×512 上传.
/// - 改过内容后返回时确认是否放弃.
/// - 封禁中不能保存, 入口和保存时都拦截.
class EditProfilePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final CurrentUser? _user = switch (ref.read(sessionProvider)) {
    SignedIn(:final user) => user,
    SignedOut() || Guest() => null,
  };
  late final _nickname = TextEditingController(text: _user?.nickname ?? '');
  late final _signature = TextEditingController(text: _user?.signature ?? '');
  AvatarDraft? _avatar;
  String? _nicknameError;
  String? _signatureError;

  /// 已保存或已确认放弃, 返回时不再拦截.
  var _leaving = false;

  @override
  void initState() {
    super.initState();
    _nickname.addListener(_onChanged);
    _signature.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _signature.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _dirty =>
      _avatar != null ||
      _nickname.text.trim() != (_user?.nickname ?? '') ||
      _signature.text.trim() != (_user?.signature ?? '');

  Future<void> _changeAvatar() async {
    final source = await showPanel<_Source>(
      context,
      builder: (panel) => EatPanel(
        title: '换头像',
        subtitle: '选好后可以拖动、缩放，放进圆圈里',
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
      if (photo == null || !mounted) return;
      final crop = await Navigator.of(context).push(
        AvatarCropPage.route(
          image: MemoryImage(photo.bytes),
          width: photo.width,
          height: photo.height,
        ),
      );
      if (crop == null) return;
      final jpeg = await picker.cropSquare(
        photo,
        centerX: crop.centerX,
        centerY: crop.centerY,
        diameter: crop.diameter,
      );
      if (mounted) {
        setState(() => _avatar = AvatarDraft(photo: photo, jpeg: jpeg));
      }
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

  Future<void> _save() async {
    final nicknameError = ProfileRules.nicknameError(_nickname.text);
    final signatureError = ProfileRules.signatureError(_signature.text);
    setState(() {
      _nicknameError = nicknameError;
      _signatureError = signatureError;
    });
    if (nicknameError != null || signatureError != null) return;
    if (!_dirty) {
      BackFallback.back(context);
      return;
    }
    if (!await guardAction(context, ref, Capability.editProfile)) return;
    try {
      await ref
          .read(profileSaverProvider.notifier)
          .save(
            nickname: _nickname.text,
            signature: _signature.text,
            avatar: _avatar,
          );
      if (!mounted) return;
      showToast(context, '资料已保存');
      _leave();
    } on AppFailure catch (e) {
      if (!mounted) return;
      await reportActionFailure(
        context,
        ref,
        e,
        capability: Capability.editProfile,
        fallback: '保存失败，请重试',
      );
    }
  }

  /// 返回. 改过内容时需确认是否放弃, 保存中不能返回.
  Future<void> _back() async {
    if (ref.read(profileSaverProvider)) return;
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
      await showPanel<bool>(
        context,
        builder: (panel) => EatPanel(
          title: '放弃修改？',
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
          child: Text(
            '改过的头像、昵称和签名都不会保存。',
            style: panel.eat.text.body.copyWith(
              color: panel.eat.colors.inkSoft,
            ),
          ),
        ),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final saving = ref.watch(profileSaverProvider);
    final user = _user;
    final name = _nickname.text.trim().isEmpty
        ? user?.nickname ?? '同学'
        : _nickname.text.trim();
    final avatar = _avatar;
    final counter = eat.text.count.copyWith(color: c.inkMuted);
    Widget count(String value, int max) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${ProfileRules.lengthOf(value)}', style: counter),
          TextSpan(text: ' / $max', style: counter),
        ],
      ),
    );
    return PopScope(
      canPop: _leaving || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: PlainScaffold(
        title: '编辑资料',
        onBack: _back,
        actions: [
          EatTappable(
            onTap: saving ? null : _save,
            label: '保存',
            builder: (context, _) => SizedBox(
              height: EatSize.touch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    saving ? '保存中' : '保存',
                    style: eat.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: saving ? c.disabledFg : c.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: EatSpace.s14),
                Center(
                  child: EatTappable(
                    onTap: saving ? null : _changeAvatar,
                    label: '换头像',
                    focusShape: const CircleBorder(),
                    builder: (context, _) => EatAvatar(
                      name: name,
                      color: avatarColorOf(user?.id ?? 0),
                      image: avatar != null
                          ? MemoryImage(avatar.jpeg)
                          : networkImage(user?.avatarUrl, width: 96),
                      size: 96,
                    ),
                  ),
                ),
                const SizedBox(height: EatSpace.s10),
                Center(
                  child: EatButton.mist(
                    '换头像',
                    icon: EatIcons.camera,
                    height: 36,
                    onPressed: saving ? null : _changeAvatar,
                  ),
                ),
                const SizedBox(height: 28),
                EatFormField(
                  label: '昵称',
                  controller: _nickname,
                  hintText:
                      '${ProfileRules.nicknameMin}–${ProfileRules.nicknameMax} 个字，可以重复',
                  textInputAction: TextInputAction.next,
                  errorText: _nicknameError,
                  trailing: count(_nickname.text, ProfileRules.nicknameMax),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(ProfileRules.nicknameMax),
                  ],
                ),
                const SizedBox(height: 26),
                EatFormField(
                  label: '签名，选填',
                  controller: _signature,
                  hintText: '一句话介绍自己',
                  textInputAction: TextInputAction.done,
                  errorText: _signatureError,
                  trailing: count(_signature.text, ProfileRules.signatureMax),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(ProfileRules.signatureMax),
                  ],
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: EatSpace.s24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
