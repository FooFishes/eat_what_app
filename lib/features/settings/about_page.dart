import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/core/platform/hot_update.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 关于页面: 应用说明, 版本号, 反馈入口和两份协议.
///
/// 游客也能进. 游客点 "反馈" 时弹登录对话框.
///
/// 版本写作 "版本 0.3.0（30）补丁 2", 依次是版本名, 构建号和热更新的补丁号. 没有补丁时不显示补丁号.
class AboutPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final config = ref.watch(appConfigProvider);
    final version = ref.watch(appVersionProvider).value;
    final build = ref.watch(appBuildNumberProvider).value;
    final hasBuild = build != null && build.isNotEmpty;
    final patch = ref.watch(currentPatchProvider).value;
    void open(String url) {
      if (url.isNotEmpty) ref.read(browserProvider).open(Uri.parse(url));
    }

    return PlainScaffold(
      title: '关于',
      slivers: [
        SliverList.list(
          children: [
            if (version != null)
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '版本 '),
                    TextSpan(text: version, style: eat.text.count),
                    if (hasBuild) ...[
                      const TextSpan(text: '（'),
                      TextSpan(text: build, style: eat.text.count),
                      const TextSpan(text: '）'),
                    ],
                    if (patch != null) ...[
                      TextSpan(text: hasBuild ? '补丁 ' : ' 补丁 '),
                      TextSpan(text: '$patch', style: eat.text.count),
                    ],
                  ],
                ),
                style: eat.text.meta.copyWith(color: c.inkMuted),
              ),
            const SizedBox(height: EatSpace.s20),
            SettingsRow(
              icon: EatIcons.feedback,
              label: '反馈',
              value: '问题反馈与建议',
              onTap: () async {
                if (await guardAction(context, ref, Capability.feedback) &&
                    context.mounted) {
                  await context.push(Paths.feedback());
                }
              },
            ),
            SettingsRow(
              icon: EatIcons.document,
              label: '隐私政策',
              onTap: () => open(config.privacyUrl),
            ),
            SettingsRow(
              icon: EatIcons.document,
              label: '用户协议',
              onTap: () => open(config.termsUrl),
            ),
            const SizedBox(height: EatSpace.s16),
            Text(
              '反馈问题时请附上版本号，便于排查。',
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: EatSpace.s8),
            Text(
              '沙软今天吃什么由学生独立开发，与学校无隶属关系。',
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ],
    );
  }
}
