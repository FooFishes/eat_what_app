import 'package:eat/design/theme/eat_theme.dart';
import 'package:material_ui/material_ui.dart';

class EatApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '沙软今天吃什么',
      theme: eatThemeData(),
      themeMode: ThemeMode.light,
      home: const Scaffold(body: Center(child: Text('沙软今天吃什么'))),
    );
  }
}
