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

// TODO: 反馈没有接口, 入口带 "待接入". 接口上线后接入并去掉标记.
// TODO: 热更新未接入, 只显示版本号, 不显示补丁号. 接入热更新后在版本号旁显示补丁号.
/// 关于页面: 应用说明, 版本号, 反馈入口和两份协议.
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
      subtitle: '沙软今天吃什么由学生独立开发，与学校无隶属关系。',
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
              value: '问题与建议',
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
              '反馈问题时请附上版本号，便于排查。',
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ],
    );
  }
}
