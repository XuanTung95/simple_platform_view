
import 'package:flutter/material.dart';
import 'package:simple_platform_view_example/clone_webview_screen.dart';

import 'clone_google_map_screen.dart';

class SelectScreen extends StatefulWidget {
  const SelectScreen({Key? key}) : super(key: key);

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select test page'),),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const CloneGoogleMapScreen();
              }));
              }, child: const Text('Clone Google Map screen'),
            ),
            const SizedBox(height: 16,),
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const CloneWebviewScreen();
              }));
            }, child: const Text('Clone Webview screen'),
            ),
          ],
        ),
      ),
    );
  }
}
