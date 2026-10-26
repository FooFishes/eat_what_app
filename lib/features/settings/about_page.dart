import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/platform/browser.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 关于（`G-SettingsAbout`）：一句说明、版本号，反馈和两份协议。
///
/// 反馈还没有接口，带「待接入」；补丁号等热更新接入后加（开发计划阶段五）。
class AboutPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final config = ref.watch(appConfigProvider);
    final version = ref.watch(appVersionProvider).value;
    void open(String url) {
      if (url.isNotEmpty) ref.read(browserProvider).open(Uri.parse(url));
    }

    return PlainScaffold(
      title: '关于',
      subtitle: '沙软今天吃什么是同学自己做的，和学校没有隶属关系。',
      slivers: [
        SliverList.list(
          children: [
            if (version != null)
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '版本 '),
                    TextSpan(text: version, style: eat.text.count),
                  ],
                ),
                style: eat.text.meta.copyWith(color: c.inkMuted),
              ),
            const SizedBox(height: EatSpace.s20),
            const SettingsRow(
              icon: EatIcons.feedback,
              label: '反馈',
              value: '出问题、提建议都行',
              pending: true,
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
              '反馈问题时带上版本号，我们查得更快。',
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ],
    );
  }
}
