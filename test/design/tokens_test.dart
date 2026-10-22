/// 逐项比对 Dart 里转写的令牌和 `prototype/design-system/tokens.json`。
///
/// 设计更新导出 `tokens.json` 后跑这个测试，就知道哪些值没同步；两边多一项、少一项也会报错。
library;

import 'dart:convert';
import 'dart:io';

import 'package:eat/design/theme/eat_colors.dart';
import 'package:eat/design/theme/eat_shadows.dart';
import 'package:eat/design/theme/eat_text_styles.dart';
import 'package:eat/design/tokens/eat_layout.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tokens = jsonDecode(
    File('prototype/design-system/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  Map<String, String> valuesOf(String group) => {
    for (final token in (tokens[group] as Map)['tokens'] as List)
      token['name'] as String: token['value'] as String,
  };

  group('颜色', () {
    final colors = valuesOf('color');

    test('EatPalette 和 tokens.json 一一对应', () {
      const palette = {
        'ink': EatPalette.ink,
        'ink-muted': EatPalette.inkMuted,
        'ink-soft': EatPalette.inkSoft,
        'paper': EatPalette.paper,
        'mist': EatPalette.mist,
        'ink-top': EatPalette.inkTop,
        'mist-top': EatPalette.mistTop,
        'paper-bottom': EatPalette.paperBottom,
        'tag-selected': EatPalette.tagSelected,
        'hairline': EatPalette.hairline,
        'handle': EatPalette.handle,
        'scrim': EatPalette.scrim,
        'line-strong': EatPalette.lineStrong,
        'disabled-bg': EatPalette.disabledBg,
        'disabled-fg': EatPalette.disabledFg,
        'warn': EatPalette.warn,
        'map-me': EatPalette.mapMe,
        'map-ground': EatPalette.mapGround,
        'map-block': EatPalette.mapBlock,
        'map-park': EatPalette.mapPark,
        'stage-broth': EatPalette.stageBroth,
        'stage-mango': EatPalette.stageMango,
        'stage-bamboo': EatPalette.stageBamboo,
        'stage-chili': EatPalette.stageChili,
        'stage-tomato': EatPalette.stageTomato,
        'stage-redoil': EatPalette.stageRedoil,
        'stage-soy': EatPalette.stageSoy,
        'stage-porcelain': EatPalette.stagePorcelain,
        'stage-matcha': EatPalette.stageMatcha,
        'stage-ghost-light': EatPalette.stageGhostLight,
        'stage-ghost-dark': EatPalette.stageGhostDark,
        'table-light': EatPalette.tableLight,
        'table-dark': EatPalette.tableDark,
        'table-ring-light': EatPalette.tableRingLight,
        'table-ring-dark': EatPalette.tableRingDark,
        'crop-ground': EatPalette.cropGround,
        'crop-panel': EatPalette.cropPanel,
        'crop-scrim': EatPalette.cropScrim,
      };
      expect(palette.keys.toSet(), colors.keys.toSet());
      for (final MapEntry(key: name, value: color) in palette.entries) {
        expectColor(color, colors[name]!, name);
      }
    });

    test('EatColors.light 每一项取的是同名令牌', () {
      const c = EatColors.light;
      final wired = {
        'ink': c.ink,
        'ink-muted': c.inkMuted,
        'ink-soft': c.inkSoft,
        'paper': c.paper,
        'mist': c.mist,
        'ink-top': c.inkTop,
        'mist-top': c.mistTop,
        'paper-bottom': c.paperBottom,
        'tag-selected': c.tagSelected,
        'hairline': c.hairline,
        'handle': c.handle,
        'scrim': c.scrim,
        'line-strong': c.lineStrong,
        'disabled-bg': c.disabledBg,
        'disabled-fg': c.disabledFg,
        'warn': c.warn,
        'map-me': c.mapMe,
        'map-ground': c.mapGround,
        'map-block': c.mapBlock,
        'map-park': c.mapPark,
        'crop-ground': c.cropGround,
        'crop-panel': c.cropPanel,
        'crop-scrim': c.cropScrim,
      };
      final stageOnly = colors.keys.where(
        (name) => name.startsWith('stage-') || name.startsWith('table-'),
      );
      expect(
        wired.keys.toSet(),
        colors.keys.toSet().difference(stageOnly.toSet()),
        reason: '舞台以外的颜色都要在 EatColors 里',
      );
      for (final MapEntry(key: name, value: color) in wired.entries) {
        expectColor(color, colors[name]!, name);
      }
    });

    test('StageColor 的 9 个值和 stage-* 一一对应', () {
      final stageTokens = colors.keys.where(
        (name) => name.startsWith('stage-') && !name.startsWith('stage-ghost'),
      );
      expect(
        StageColor.values.map((s) => s.token).toSet(),
        stageTokens.toSet(),
      );
      for (final stage in StageColor.values) {
        expectColor(stage.color, colors[stage.token]!, stage.token);
      }
    });
  });

  test('文字样式', () {
    final type = tokens['type'] as Map<String, dynamic>;
    final s = EatTextStyles.standard;
    final styles = {
      'stage-dish': s.stageDish,
      'login-display': s.loginDisplay,
      'page-title': s.pageTitle,
      'question-title': s.questionTitle,
      'profile-name': s.profileName,
      'section-title': s.sectionTitle,
      'tab-active': s.tabActive,
      'tab': s.tab,
      'row-title': s.rowTitle,
      'tile-title': s.tileTitle,
      'body': s.body,
      'button-label': s.buttonLabel,
      'meta': s.meta,
      'caption': s.caption,
      'nav-label': s.navLabel,
      'price-hero': s.priceHero,
      'stat': s.stat,
      'price-inline': s.priceInline,
      'distance': s.distance,
      'count': s.count,
    };
    final seen = <String>{};
    for (final group in type['groups'] as List) {
      final family = group['family'] == 'numeral'
          ? EatFonts.numeral
          : EatFonts.sans;
      for (final token in group['styles'] as List) {
        final name = token['name'] as String;
        seen.add(name);
        final style = styles[name];
        expect(style, isNotNull, reason: '$name 没有转写');
        final size = px(token['fontSize'] as String);
        expect(style!.fontFamily, family, reason: name);
        expect(style.fontSize, size, reason: name);
        expect(
          style.height! * size,
          closeTo(px(token['lineHeight'] as String), 1e-9),
          reason: name,
        );
        expect(style.leadingDistribution, TextLeadingDistribution.even);
        expect(style.fontWeight!.value, token['fontWeight'], reason: name);
        final letterSpacing = token['letterSpacing'] as String?;
        expect(
          style.letterSpacing,
          letterSpacing == null ? isNull : px(letterSpacing),
          reason: name,
        );
        if (family == EatFonts.numeral) {
          expect(style.fontVariations, [
            FontVariation.opticalSize(size),
          ], reason: '$name 的光学尺寸要等于字号');
        }
      }
    }
    expect(seen, styles.keys.toSet());
  });

  test('间距', () {
    expect(valuesOf('spacing').map((k, v) => MapEntry(k, px(v))), {
      'space-4': EatSpace.s4,
      'space-8': EatSpace.s8,
      'space-10': EatSpace.s10,
      'space-14': EatSpace.s14,
      'space-16': EatSpace.s16,
      'space-20': EatSpace.s20,
      'space-24': EatSpace.s24,
    });
  });

  test('圆角', () {
    final radius = valuesOf('radius');
    // 正圆不转写成圆角，组件用 BoxShape.circle。
    expect(radius.remove('radius-plate'), '50%');
    expect(radius.map((k, v) => MapEntry(k, px(v))), {
      'radius-pill': EatRadius.pill.x,
      'radius-sheet': EatRadius.sheet.x,
      'radius-tile': EatRadius.tile.x,
      'radius-thumb-lg': EatRadius.thumbLg.x,
      'radius-thumb': EatRadius.thumb.x,
    });
  });

  test('尺寸', () {
    expect(valuesOf('size').map((k, v) => MapEntry(k, px(v))), {
      'size-touch': EatSize.touch,
      'size-button': EatSize.button,
      'size-chip': EatSize.chip,
      'size-nav': EatSize.nav,
      'size-avatar': EatSize.avatar,
      'size-thumb': EatSize.thumb,
      'size-thumb-lg': EatSize.thumbLg,
      'size-stage': EatSize.stage,
      'size-plate': EatSize.plate,
      'size-turntable-radius': EatSize.turntableRadius,
    });
  });

  test('阴影', () {
    const s = EatShadows.standard;
    final shadows = {
      'shadow-plate': s.plate,
      'shadow-float': s.float,
      'shadow-fab': s.fab,
      'shadow-button': s.button,
      'shadow-button-pressed': s.buttonPressed,
      'shadow-button-light': s.buttonLight,
      'shadow-button-light-pressed': s.buttonLightPressed,
      'shadow-button-outline': s.buttonOutline,
      'shadow-button-on-stage': s.buttonOnStage,
      'shadow-button-ghost': s.buttonGhost,
      'shadow-pin': s.pin,
      'shadow-sheet': s.sheet,
    };
    final css = valuesOf('shadow');
    expect(shadows.keys.toSet(), css.keys.toSet());
    for (final MapEntry(key: name, value: shadow) in shadows.entries) {
      final parsed = parseShadows(css[name]!);
      expectShadows(shadow.outer, parsed.outer, '$name 外阴影');
      expectShadows(shadow.inset, parsed.inset, '$name 内阴影');
    }
  });
}

double px(String value) => double.parse(value.replaceFirst('px', ''));

final _rgba = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)');
final _hex = RegExp(r'#([0-9a-fA-F]{6})');

/// 解析 `#rrggbb` 或 `rgba(r, g, b, a)`。
Color parseColor(String css) {
  final rgba = _rgba.firstMatch(css);
  if (rgba != null) {
    return Color.fromRGBO(
      int.parse(rgba[1]!),
      int.parse(rgba[2]!),
      int.parse(rgba[3]!),
      double.parse(rgba[4]!),
    );
  }
  return Color(0xFF000000 | int.parse(_hex.firstMatch(css)![1]!, radix: 16));
}

void expectColor(Color actual, String css, String name) {
  final expected = parseColor(css);
  for (final (channel, a, e) in [
    ('r', actual.r, expected.r),
    ('g', actual.g, expected.g),
    ('b', actual.b, expected.b),
    ('a', actual.a, expected.a),
  ]) {
    expect(a, closeTo(e, 1e-6), reason: '$name 的 $channel 通道：应为 $css');
  }
}

/// 解析 CSS 的 `box-shadow`，按 Flutter 的绘制顺序（和 CSS 相反）分成外阴影和内阴影。
({List<BoxShadow> outer, List<BoxShadow> inset}) parseShadows(String css) {
  final outer = <BoxShadow>[];
  final inset = <BoxShadow>[];
  for (final part in css.split(RegExp(r',(?![^(]*\))'))) {
    final colorText = (_rgba.firstMatch(part) ?? _hex.firstMatch(part))![0]!;
    final words = part.replaceFirst(colorText, '').trim().split(RegExp(r'\s+'));
    final isInset = words.first == 'inset';
    final lengths = words.skip(isInset ? 1 : 0).map(px).toList();
    final shadow = BoxShadow(
      offset: Offset(lengths[0], lengths[1]),
      blurRadius: lengths.length > 2 ? lengths[2] : 0,
      spreadRadius: lengths.length > 3 ? lengths[3] : 0,
      color: parseColor(colorText),
    );
    (isInset ? inset : outer).insert(0, shadow);
  }
  return (outer: outer, inset: inset);
}

void expectShadows(
  List<BoxShadow> actual,
  List<BoxShadow> expected,
  String name,
) {
  expect(actual, hasLength(expected.length), reason: name);
  for (var i = 0; i < actual.length; i++) {
    expect(actual[i].offset, expected[i].offset, reason: '$name 第 $i 层');
    expect(
      actual[i].blurRadius,
      expected[i].blurRadius,
      reason: '$name 第 $i 层',
    );
    expect(
      actual[i].spreadRadius,
      expected[i].spreadRadius,
      reason: '$name 第 $i 层',
    );
    expect(
      actual[i].color.toARGB32(),
      expected[i].color.toARGB32(),
      reason: '$name 第 $i 层',
    );
  }
}
