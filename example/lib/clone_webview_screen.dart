

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:simple_platform_view_example/clone_android_webview_platform.dart';
import 'package:simple_platform_view_example/expensive_widget.dart';
import 'package:simple_platform_view_example/clone_google_maps_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CloneWebviewScreen extends StatefulWidget {
  const CloneWebviewScreen({Key? key}) : super(key: key);

  @override
  State<CloneWebviewScreen> createState() => _CloneWebviewScreenState();
}

class _CloneWebviewScreenState extends State<CloneWebviewScreen> {
  late WebViewController webViewController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    /// Replace WebViewPlatform.instance with the modified version
    if (Platform.isAndroid) {
      CloneAndroidWebViewPlatform.registerWith();
    }
    webViewController = WebViewController();
    webViewController.loadRequest(Uri.parse("https://google.com"));
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clone Google Map Screen $count"),
      ),
      body: Stack(
        children: [
          Center(
            child: SizedBox.expand(
              child: WebViewWidget(controller: webViewController),
            ),
          ),
          const ExpensiveWidget(),
          Center(
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  count++;
                });
                webViewController.loadRequest(Uri.parse("https://google.com"));
              },
              child: const Icon(Icons.abc),
            ),
          ),
        ],
      ),
    );
  }
}
