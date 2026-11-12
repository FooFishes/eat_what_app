import 'package:eat/design/theme/eat_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('没挂 EatTheme 时退回浅色主题', (tester) async {
    late EatTheme seen;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = context.eat;
          return const SizedBox();
        },
      ),
    );

    expect(seen, same(EatTheme.light));
  });
}
