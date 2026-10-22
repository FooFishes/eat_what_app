import 'package:material_ui/material_ui.dart';

class EatApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '沙软今天吃什么',
      home: Scaffold(body: Center(child: Text('沙软今天吃什么'))),
    );
  }
}
