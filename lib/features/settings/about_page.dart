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
import 'package:eat/features/settings/widgets/settings_group.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 关于页面: 最上面是放大的版本号, 下面是反馈与我的反馈, 再下面一组不带图标的隐私政策, 用户协议, 开发团队, 开源声明.
///
/// 允许游客访问, 游客点击 "反馈" 或 "我的反馈" 时会弹出登录拦截对话框.
/// 版本名用大号数字写在最上面, 右边小字写构建号与热更新补丁号 ("构建 30  补丁 2"), 无补丁时省略补丁号; 下面一句提醒转述时把这些都说全.
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
              Semantics(
                container: true,
                label: [
                  [
                    '版本 $version',
                    if (hasBuild) '构建 $build',
                    if (patch != null) '补丁 $patch',
                  ].join('，'),
                  '如需要向他人提供版本号，请将所有内容进行转述。',
                ].join('。'),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        '版本',
                        style: eat.text.meta.copyWith(color: c.inkMuted),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        spacing: EatSpace.s10,
                        children: [
                          Text(
                            version,
                            style: eat.text.stat.copyWith(
                              fontSize: 40,
                              height: 48 / 40,
                              color: c.ink,
                            ),
                          ),
                          if (hasBuild || patch != null)
                            Flexible(
                              child: Text(
                                [
                                  if (hasBuild) '构建 $build',
                                  if (patch != null) '补丁 $patch',
                                ].join('  '),
                                style: eat.text.count.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: EatSpace.s4),
                      Text(
                        '如需要向他人提供版本号，请将所有内容进行转述。',
                        style: eat.text.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: EatSpace.s24),
            SettingsGroup(
              children: [
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
                  icon: EatIcons.history,
                  label: '我的反馈',
                  value: '提交记录与处理结果',
                  onTap: () async {
                    if (await guardAction(context, ref, Capability.feedback) &&
                        context.mounted) {
                      await context.push(Paths.myFeedback);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: EatSpace.s16),
            SettingsGroup(
              dividerIndent: 0,
              children: [
                SettingsRow(
                  label: '隐私政策',
                  onTap: () => open(config.privacyUrl),
                ),
                SettingsRow(label: '用户协议', onTap: () => open(config.termsUrl)),
                SettingsRow(
                  label: '开发团队',
                  onTap: () => context.push(Paths.team),
                ),
                SettingsRow(
                  label: '开源声明',
                  onTap: () => context.push(Paths.licenses),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
