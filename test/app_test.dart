import 'package:eat/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('启动后显示应用名', (tester) async {
    await tester.pumpWidget(const EatApp());

    expect(find.text('沙软今天吃什么'), findsOneWidget);
  });
}
