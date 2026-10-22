/// 检查 `lib/` 的分层方向和导入约定，规则和技术架构文档「依赖方向」一节的表一致。
///
/// 只用正则读 import / export 指令，不依赖分析器：指令总在文件开头，格式由
/// `dart format` 固定，正则足够，也不用把 `analyzer` 加成直接依赖。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final libFiles = _dartFiles('lib');
  final testFiles = _dartFiles('test');

  test('lib/ 只按分层方向导入', () {
    final violations = <String>[];
    for (final file in libFiles) {
      final from = _libPath(file);
      final fromLayer = _layerOf(from);
      if (fromLayer == null) {
        violations.add('$from：不在任何一层里，先在技术架构文档里登记目录');
        continue;
      }
      for (final uri in _importedUris(file)) {
        final target = _resolveInLib(from, uri);
        final problem = target == null
            ? _externalProblem(fromLayer, uri)
            : _internalProblem(from, fromLayer, target);
        if (problem != null) violations.add('$from → $uri：$problem');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('不直接导入 material.dart 和 flutter_localizations', () {
    final violations = [
      for (final file in [...libFiles, ...testFiles])
        for (final uri in _importedUris(file))
          if (uri == 'package:flutter/material.dart' ||
              uri.startsWith('package:flutter_localizations/'))
            '${file.path} → $uri',
    ];
    expect(
      violations,
      isEmpty,
      reason:
          '用 package:material_ui/material_ui.dart：\n${violations.join('\n')}',
    );
  });

  test('包内跨目录的导入用 package:eat/', () {
    final violations = [
      for (final file in libFiles)
        for (final uri in _importedUris(file))
          if (!uri.contains(':') && uri.contains('/')) '${file.path} → $uri',
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

/// 每一层能导入的 `lib/` 内的层。`design/tokens` 谁都能导入，不必列出。
const _allowedLayers = <String, Set<String>>{
  'core': {'core'},
  'design/tokens': {},
  'design': {'core', 'design'},
  'domain': {'domain'},
  'data': {'core', 'domain', 'data'},
  'state': {'core', 'domain', 'data', 'state'},
  'features': {'core', 'design', 'domain', 'data', 'state', 'features'},
};

/// 功能目录唯一能导入的 `router/` 文件：跳转用的路径常量。
const _routerPathsFile = 'router/paths.dart';

/// `domain` 是纯 Dart 的产品规则，只能用这些外部库。
const _domainExternals = {
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:math',
  'dart:typed_data',
};

List<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// `lib/` 下的相对路径，分隔符统一成 `/`。
String _libPath(File file) =>
    file.path.replaceAll(r'\', '/').replaceFirst(RegExp('^lib/'), '');

/// 文件所在的层；`lib/` 根下的入口文件（main、bootstrap、app）返回 `root`。
String? _layerOf(String libPath) {
  final segments = libPath.split('/');
  if (segments.length == 1) return 'root';
  if (segments[0] == 'design' && segments[1] == 'tokens') {
    return 'design/tokens';
  }
  const layers = {
    'core',
    'design',
    'domain',
    'data',
    'state',
    'features',
    'router',
  };
  return layers.contains(segments[0]) ? segments[0] : null;
}

final _directive = RegExp(r'^(?:import|export)\s[^;]*;', multiLine: true);
final _quoted = RegExp(r'''['"]([^'"]+)['"]''');

/// 文件里 import / export 的全部 URI，条件导入的每个分支都算。
Iterable<String> _importedUris(File file) sync* {
  for (final directive in _directive.allMatches(file.readAsStringSync())) {
    for (final uri in _quoted.allMatches(directive[0]!)) {
      yield uri[1]!;
    }
  }
}

/// 指向 `lib/` 内的 URI 转成 `lib/` 下的路径；外部库返回 null。
String? _resolveInLib(String from, String uri) {
  const self = 'package:eat/';
  if (uri.startsWith(self)) return uri.substring(self.length);
  if (uri.contains(':')) return null;
  return Uri.parse('file:///$from').resolve(uri).path.substring(1);
}

String? _externalProblem(String fromLayer, String uri) {
  if (fromLayer == 'design/tokens' && !uri.startsWith('dart:')) {
    return 'design/tokens 只能用 dart: 库';
  }
  if (fromLayer == 'domain' && !_domainExternals.contains(uri)) {
    return 'domain 是纯 Dart，不能用 Flutter、IO 和第三方包';
  }
  return null;
}

String? _internalProblem(String from, String fromLayer, String target) {
  final targetLayer = _layerOf(target);
  if (targetLayer == 'design/tokens' || fromLayer == 'router') return null;
  if (fromLayer == 'root') return null;
  if (targetLayer == 'root') return '入口文件只能由入口文件导入';
  if (fromLayer == 'features') {
    if (target == _routerPathsFile) return null;
    if (targetLayer == 'features' && _featureOf(target) != _featureOf(from)) {
      return '功能之间不互相导入，跳转用 router/paths.dart 的路径';
    }
  }
  final allowed = _allowedLayers[fromLayer]!;
  return allowed.contains(targetLayer) ? null : '$fromLayer 不能依赖 $targetLayer';
}

String _featureOf(String libPath) => libPath.split('/')[1];
