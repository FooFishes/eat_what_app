import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_form_field.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_nav_bar.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/eat_stage.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:flutter/widgets.dart';

/// 组件页：设计规范里的组件和它们的各种状态摆在一页，对照 `G-Kit` 画板检查。只在 debug 构建里有。
///
/// 按下、键盘焦点（按 Tab 键）这类状态要亲手试，页面上的组件都是能操作的。
class KitPage extends StatefulWidget {
  const new({super.key});

  @override
  State<KitPage> createState() => _KitPageState();
}

class _KitPageState extends State<KitPage> {
  var _stage = 0;
  var _choice = 0;
  final _tags = {0, 2};
  var _tab = 0;
  var _radio = 0;
  var _publicFollows = true;
  var _likes = false;
  var _nav = 0;

  static const _stageNames = {
    StageColor.broth: '汤色',
    StageColor.mango: '芒果黄',
    StageColor.bamboo: '竹屉',
    StageColor.chili: '辣橙',
    StageColor.porcelain: '青花蓝',
    StageColor.matcha: '抹茶绿',
    StageColor.tomato: '番茄红',
    StageColor.redoil: '红油',
    StageColor.soy: '酱色',
  };

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    String hex(Color color) =>
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    Widget section(String title, List<Widget> children) => SliverPadding(
      padding: const EdgeInsets.only(bottom: 32),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EatSpace.s14,
          children: [
            Text(
              title,
              style: eat.text.meta.copyWith(
                fontWeight: FontWeight.w500,
                color: c.inkMuted,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );

    Widget stageCard(StageColor stage, Widget child) => ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: EatStage(
        stage: stage,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

    final cycling = StageColor.values[_stage % StageColor.values.length];

    return PlainScaffold(
      title: '组件',
      slivers: [
        section('舞台色取自当前那道菜，墨色与白色是唯一的固定色', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final stage in StageColor.values)
                SizedBox(
                  width: 104,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(EatRadius.thumb),
                    child: EatStage(
                      stage: stage,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stageNames[stage]!,
                              style: eat.text.rowTitle.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              hex(stage.color),
                              style: eat.text.distance.copyWith(
                                color: stage.foreground,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '次级文字',
                              style: eat.text.meta.copyWith(
                                color: stage.secondaryForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ]),
        section('黑体 900 做主角，Bricolage Grotesque 只用于数字', [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 20,
            runSpacing: 8,
            children: [
              Text(
                '鲜虾蟹籽\n云吞',
                textScaler: TextScaler.noScaling,
                style: eat.text.stageDish,
              ),
              Text(
                '¥18',
                textScaler: TextScaler.noScaling,
                style: eat.text.priceHero,
              ),
            ],
          ),
          Text('袁记云饺，距你 320 m', style: eat.text.body),
        ]),
        section('舞台上的按钮跟着舞台色变；点「换一个」看换色过渡', [
          stageCard(
            cycling,
            Row(
              spacing: EatSpace.s10,
              children: [
                Expanded(
                  child: EatButton.stageGhost(
                    '换一个',
                    icon: EatIcons.shuffle,
                    onPressed: () => setState(() => _stage++),
                  ),
                ),
                Expanded(child: EatButton.stageSolid('就它了', onPressed: () {})),
              ],
            ),
          ),
          stageCard(
            StageColor.redoil,
            Row(
              spacing: EatSpace.s10,
              children: [
                Expanded(child: EatButton.stageGhost('换一个', onPressed: () {})),
                Expanded(child: EatButton.stageSolid('就它了', onPressed: () {})),
              ],
            ),
          ),
          stageCard(
            StageColor.porcelain,
            const SizedBox(height: 300, child: StagePlaceholder()),
          ),
        ]),
        section('白色抽屉里的按钮，按住看下沉；不可用时扁平', [
          Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.outline(
                  '导航去店里',
                  icon: EatIcons.navigate,
                  onPressed: () {},
                ),
              ),
              Expanded(child: EatButton.solid('加一道菜', onPressed: () {})),
            ],
          ),
          Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(child: EatButton.mist('换一个', onPressed: () {})),
              Expanded(child: EatButton.dashed('＋ 新建一家店', onPressed: () {})),
            ],
          ),
          const Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(child: EatButton.solid('账号密码登录', onPressed: null)),
              Expanded(child: EatButton.dashed('＋ 自己写', onPressed: null)),
            ],
          ),
          Text('勾选后才能登录', style: eat.text.meta.copyWith(color: c.warn)),
          Wrap(
            spacing: EatSpace.s10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EatButton.solid('回关', height: 36, onPressed: () {}),
              EatButton.mist('已关注', height: 36, onPressed: () {}),
              EatIconButton(EatIcons.share, label: '分享', onPressed: () {}),
              EatIconButton(EatIcons.more, label: '更多', onPressed: () {}),
            ],
          ),
        ]),
        section('标签：单选、多选、补充入口、待接入', [
          Wrap(
            spacing: EatSpace.s8,
            children: [
              for (final (i, name) in ['主食', '小吃', '饮品', '甜品', '火锅'].indexed)
                EatChip.choice(
                  name,
                  selected: _choice == i,
                  onTap: () => setState(() => _choice = i),
                ),
            ],
          ),
          Wrap(
            spacing: EatSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (i, name) in ['平价', '量大', '鲜虾大只'].indexed)
                EatChip.tag(
                  name,
                  selected: _tags.contains(i),
                  onTap: () => setState(
                    () => _tags.contains(i) ? _tags.remove(i) : _tags.add(i),
                  ),
                ),
              EatChip.add('＋ 自己写', onTap: () {}),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: EatSpace.s8,
                children: [
                  Text('评分', style: eat.text.body),
                  const PendingTag(),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(EatSpace.s14),
            decoration: BoxDecoration(
              color: c.mapGround,
              borderRadius: const BorderRadius.all(EatRadius.tile),
            ),
            child: Wrap(
              spacing: EatSpace.s8,
              children: [
                EatChip.district('万达金街', selected: true, onTap: () {}),
                EatChip.district('软件园', selected: false, onTap: () {}),
              ],
            ),
          ),
        ]),
        section('分类：选中项用字重说话', [
          EatTabs(
            tabs: const [
              EatTabItem('今日推荐'),
              EatTabItem('主食'),
              EatTabItem('小吃'),
              EatTabItem('饮品'),
              EatTabItem('甜品'),
            ],
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          EatTabs(
            tabs: const [
              EatTabItem('上传', count: 42),
              EatTabItem('收藏', count: 117),
              EatTabItem('评论', pending: true),
            ],
            selected: 0,
            onSelected: (_) {},
          ),
        ]),
        section('列表行：店铺、菜品、消息', [
          EatListRow(
            leading: const ListThumb(image: null, size: EatSize.thumbLg),
            title: const Text('螺蛳粉研究所'),
            lines: [
              Row(
                spacing: EatSpace.s8,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '600 m',
                    style: eat.text.distance.copyWith(color: c.ink),
                  ),
                  const Text('万达金街 B1'),
                ],
              ),
              const Text('招牌：柳州螺蛳粉'),
            ],
            onTap: () {},
          ),
          EatListRow(
            leading: const ListThumb(image: null, size: 56),
            title: const Text('红烧肉'),
            lines: const [Text('64 人收藏')],
            trailing: Text('¥38', style: eat.text.priceInline),
            action: EatIconButton(
              EatIcons.bookmarkOn,
              label: '已收藏',
              onPressed: () {},
            ),
          ),
          EatListRow(
            unread: true,
            leading: const EatAvatar(name: '小林', color: StageColor.broth),
            title: Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: '小林',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' 收藏了你上传的玉米排骨汤'),
                ],
              ),
              style: eat.text.body.copyWith(fontWeight: FontWeight.w400),
            ),
            lines: [
              Text(
                '12 分钟前',
                style: eat.text.caption.copyWith(color: c.inkMuted),
              ),
            ],
            trailing: const ListThumb(image: null, size: 48),
            onTap: () {},
          ),
        ]),
        section('单选行和开关', [
          for (final (i, (name, distance, place)) in [
            ('螺蛳粉研究所', '600 m', '万达金街 B1'),
            ('家常小馆', '500 m', '银座商城 2 层'),
          ].indexed)
            EatRadioRow(
              title: name,
              thumbnail: const ListThumb(image: null),
              subtitle: Row(
                spacing: EatSpace.s8,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    distance,
                    style: eat.text.distance.copyWith(color: c.ink),
                  ),
                  Text(place),
                ],
              ),
              selected: _radio == i,
              onSelected: () => setState(() => _radio = i),
            ),
          EatSwitch(
            label: '公开我的关注列表',
            description: '关掉后别人点开，看到的是「对方没有公开」',
            value: _publicFollows,
            onChanged: (value) => setState(() => _publicFollows = value),
          ),
          EatSwitch(
            label: '赞和收藏',
            description: '同一道菜 1 小时内的合成一条',
            value: _likes,
            onChanged: (value) => setState(() => _likes = value),
          ),
          EatSwitch(
            label: '个性化推荐',
            value: true,
            onChanged: (_) {},
            pending: true,
          ),
        ]),
        section('输入', [
          const EatSearchField(hintText: '搜店名'),
          Container(
            padding: const EdgeInsets.all(EatSpace.s14),
            decoration: BoxDecoration(
              color: c.mapGround,
              borderRadius: const BorderRadius.all(EatRadius.tile),
            ),
            child: EatSearchField(
              hintText: '搜店名或菜名',
              floating: true,
              onFilter: () {},
            ),
          ),
          const Row(
            spacing: EatSpace.s16,
            children: [
              Expanded(
                child: EatFormField(label: '菜名', hintText: '叫什么'),
              ),
              SizedBox(width: 104, child: EatFormField.price(label: '价格')),
            ],
          ),
          const EatFormField(
            label: '菜名',
            hintText: '叫什么',
            errorText: '还没写菜名，写上大家才搜得到',
          ),
        ]),
        section('盘子和方块：插画不加盘沿；图片没加载出来时是 mist 底', [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 24,
            children: [
              for (final art in [Illustration.yuntun, Illustration.luosifen])
                DishPlate.illustration(IllustrationImage(art), size: 120),
              const ListThumb(image: null, size: 56),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EatSpace.s14,
            children: [
              Expanded(
                child: DishTile(
                  image: null,
                  name: '铁锅炖大鹅',
                  shop: '东北饭庄',
                  onTap: () {},
                ),
              ),
              Expanded(
                child: DishTile(
                  image: null,
                  name: '柳州螺蛳粉',
                  likes: 23,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ]),
        section('抽屉和面板', [
          ClipRRect(
            borderRadius: const BorderRadius.all(EatRadius.tile),
            child: ColoredBox(
              color: StageColor.porcelain.color,
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: EatSheet(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: EatSpace.s20),
                    child: Text('今日推荐', style: eat.text.sectionTitle),
                  ),
                ),
              ),
            ),
          ),
          Row(
            spacing: EatSpace.s10,
            children: [
              Expanded(
                child: EatButton.mist(
                  '举报面板',
                  onPressed: () => showPanel<void>(
                    context,
                    builder: (context) => EatPanel(
                      title: '举报这道菜',
                      actions: EatButton.solid(
                        '提交',
                        onPressed: () => Navigator.pop(context),
                      ),
                      child: Column(
                        spacing: 4,
                        children: [
                          for (final (i, reason) in [
                            '不是这道菜的实拍',
                            '广告',
                            '违法或不友善',
                          ].indexed)
                            EatRadioRow(
                              title: reason,
                              selected: i == 0,
                              onSelected: () {},
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: EatButton.mist(
                  '提示面板',
                  onPressed: () => showPanel<void>(
                    context,
                    builder: (context) => EatPanel(
                      icon: EatIcons.block,
                      title: '暂时不能发布',
                      actions: Row(
                        spacing: EatSpace.s10,
                        children: [
                          Expanded(
                            child: EatButton.mist('觉得误伤了', onPressed: () {}),
                          ),
                          Expanded(
                            child: EatButton.solid(
                              '知道了',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                      child: const PanelFacts([
                        (label: '原因', value: '多次发布和菜无关的图片', strong: false),
                        (label: '恢复', value: '10 月 25 日 12:00', strong: true),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]),
        section('底部导航：三个标签加发布按钮，悬浮在内容上', [
          EatNavBar(
            currentIndex: _nav,
            onSelected: (index) => setState(() => _nav = index),
            onPublish: () {},
          ),
        ]),
        section('加载、失败、空', [
          const TileGridPlaceholder(count: 2),
          FailureState(onRetry: () {}),
          EmptyState(
            icon: EatIcons.search,
            title: '没找到「螺蛳粉」',
            message: '换个词试试。要是这家店还没人建过，你来建第一个。',
            action: EatButton.outline(
              '新建一家店',
              icon: EatIcons.add,
              height: 48,
              onPressed: () {},
            ),
          ),
        ]),
        section('图标：24px 和 16px（16px 用加粗描边）', [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final icon in EatIcons.values)
                EatIcon(icon, size: 24, semanticLabel: icon.file),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final icon in EatIcons.values) EatIcon(icon, size: 16),
            ],
          ),
        ]),
      ],
    );
  }
}
