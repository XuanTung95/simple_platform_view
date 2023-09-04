
import 'package:flutter/material.dart';
import 'package:simple_platform_view_example/android/clone_google_maps_flutter_android.dart';
import 'package:simple_platform_view_example/screen/clone_webview_screen.dart';
import 'package:simple_platform_view_example/screen/google_map_list_view_screen.dart';
import 'package:simple_platform_view_example/screen/webview_list_view_screen.dart';

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
      appBar: AppBar(title: const Text('Select test screen'),),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const CloneGoogleMapScreen();
              }));
              }, child: const Text('Google Map screen'),
            ),
            ElevatedButton(onPressed: () async {
              CloneGoogleMapsFlutterAndroid.useVirtualDisplay = true;
              await Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const CloneGoogleMapScreen();
              }));
              CloneGoogleMapsFlutterAndroid.useVirtualDisplay = false;
            }, child: const Text('Google Map Virtual Display'),),
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const CloneWebviewScreen();
              }));
            }, child: const Text('Webview screen'),
            ),
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const GoogleMapListViewScreen();
              }));
            }, child: const Text('Google Map List View'),
            ),
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const WebViewListViewScreen();
              }));
            }, child: const Text('WebView List View'),
            ),
          ],
        ),
      ),
    );
  }
}
