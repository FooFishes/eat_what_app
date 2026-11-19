import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/features/settings/widgets/settings_group.dart';
import 'package:eat/features/settings/widgets/settings_row.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 开发团队名单, 每项是名字和分工.
const _team = <({String name, String role})>[
  (name: 'FooFish', role: 'App 开发'),
  (name: 'PyCmg', role: 'Web 开发'),
  (name: 'Jackie Ruan', role: '后端开发'),
];

/// 开发团队页: 名单和分工, 下面一行 "Made with 心形 and Token.", 心形是实心的番茄红.
class TeamPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final style = eat.text.body.copyWith(color: eat.colors.inkMuted);
    return PlainScaffold(
      title: '开发团队',
      slivers: [
        SliverList.list(
          children: [
            SettingsGroup(
              dividerIndent: 0,
              children: [
                for (final member in _team)
                  SettingsRow(label: member.name, value: member.role),
              ],
            ),
            const SizedBox(height: EatSpace.s16),
            Semantics(
              label: 'Made with love and Token.',
              child: ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Made with '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: EatIcon(
                          EatIcons.heartOn,
                          size: 20,
                          color: StageColor.tomato.color,
                        ),
                      ),
                      const TextSpan(text: ' and Token.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 开源声明页: 用到的开源组件, 点一项看许可证全文.
///
/// 开源组件取自 [LicenseRegistry]: 依赖包的许可证由 Flutter 自动登记, 内置字体, 图标和表情图片的许可证在启动时登记 (见 `bootstrap.dart`).
class OpenSourcePage extends StatefulWidget {
  const new({super.key});

  @override
  State<OpenSourcePage> createState() => _OpenSourcePageState();
}

class _OpenSourcePageState extends State<OpenSourcePage> {
  late final Future<List<String>> _names = _licensedNames();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return PlainScaffold(
      title: '开源声明',
      slivers: [
        SliverList.list(
          children: [
            FutureBuilder(
              future: _names,
              builder: (context, snapshot) => SettingsGroup(
                note: const Text('沙软今天吃什么用到了下面这些开源组件，感谢它们的作者。点一项看许可证全文。'),
                dividerIndent: 0,
                children: switch (snapshot.data) {
                  null => const [LoadingArea(child: SizedBox(height: 56))],
                  final names => [
                    for (final name in names)
                      SettingsRow(
                        label: name,
                        onTap: () => context.push(Paths.license(name)),
                      ),
                  ],
                },
              ),
            ),
            const SizedBox(height: EatSpace.s16),
            Text(
              '图标来自 MingCute，表情来自 Twemoji，字体是 Noto Sans SC 和 Inter。',
              style: eat.text.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ],
    );
  }
}

/// 登记过许可证的组件名, 按名字排序, 同名只列一次.
Future<List<String>> _licensedNames() async {
  final names = <String>{};
  await for (final entry in LicenseRegistry.licenses) {
    names.addAll(entry.packages);
  }
  return names.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

/// 一个开源组件的许可证全文. 同一组件登记了多份许可证时依次排出, 中间隔一段空.
class LicenseTextPage extends StatefulWidget {
  const new({super.key, required this.name});

  final String name;

  @override
  State<LicenseTextPage> createState() => _LicenseTextPageState();
}

class _LicenseTextPageState extends State<LicenseTextPage> {
  late final Future<List<List<LicenseParagraph>>> _licenses = () async {
    return [
      await for (final entry in LicenseRegistry.licenses)
        if (entry.packages.contains(widget.name)) entry.paragraphs.toList(),
    ];
  }();

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final style = eat.text.meta.copyWith(color: eat.colors.inkSoft);
    return PlainScaffold(
      title: widget.name,
      slivers: [
        FutureBuilder(
          future: _licenses,
          builder: (context, snapshot) => SliverList.list(
            children: switch (snapshot.data) {
              null => const [LoadingArea(child: SizedBox(height: 56))],
              final licenses => [
                for (final (i, paragraphs) in licenses.indexed) ...[
                  if (i > 0) const SizedBox(height: EatSpace.s24),
                  for (final p in paragraphs)
                    Padding(
                      padding: EdgeInsets.only(
                        left: p.indent == LicenseParagraph.centeredIndent
                            ? 0
                            : EatSpace.s16 * p.indent,
                        bottom: EatSpace.s8,
                      ),
                      child: Text(
                        p.text,
                        textAlign: p.indent == LicenseParagraph.centeredIndent
                            ? TextAlign.center
                            : TextAlign.start,
                        style: style,
                      ),
                    ),
                ],
              ],
            },
          ),
        ),
      ],
    );
  }
}
