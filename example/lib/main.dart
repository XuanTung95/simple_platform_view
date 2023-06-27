
import 'package:flutter/material.dart';
import 'package:simple_platform_view/simple_platform_view.dart';

import 'package:simple_platform_view_example/screen/select_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // clean plugin after hot restart
  await SimplePlatformView.restart();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SelectScreen(),
    );
  }
}
