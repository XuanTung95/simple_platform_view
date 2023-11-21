
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../android/clone_android_webview_platform.dart';
import '../ios/clone_webkit_webview_platform.dart';

class TestDepth extends StatefulWidget {
  const TestDepth({super.key});

  @override
  State<TestDepth> createState() => _TestDepthState();
}

class _TestDepthState extends State<TestDepth> {

  bool reversed = false;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  List<WebViewController> controllers = [];

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      CloneAndroidWebViewPlatform.registerWith();
    } else if (Platform.isIOS) {
      // CloneWebKitWebViewPlatform.registerWith();
    }
    controllers = List.generate(5, (index) {
      WebViewController webViewController = WebViewController();
      webViewController.loadRequest(Uri.parse("https://google.com"));
      webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
      return webViewController;
    });
  }

  @override
  Widget build(BuildContext context) {
    var children = [
      SizedBox(
        key: const ValueKey(1),
        width: 250,
        height: 250,
        child: buildWidgets(controllers[0]),
      ),
      SizedBox(
        key: const ValueKey(2),
        width: 200,
        height: 200,
        child: buildWidgets(controllers[1]),
      ),
      SizedBox(
        key: const ValueKey(3),
        width: 100,
        height: 100,
        child: buildWidgets(controllers[2]),
      ),
    ];
    if (reversed) {
      children = children.reversed.toList();
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            reversed = !reversed;
          });
        },
      ),
      body: Stack(
        children: [
          Positioned(
              top: 100,
              left: 10,
              child: buildWidgets(controllers[3]),
          ),
          Positioned(
            top: 150,
            left: 110,
            child: Stack(
              alignment: Alignment.center,
              children: children,
            ),
          ),
          Positioned(
            top: 110,
            left: 280,
            child: buildWidgets(controllers[4]),
          ),
        ],
      ),
    );
  }

  Widget buildWidgets(WebViewController webViewController) {
    return SizedBox(
      width: 200,
      height: 200,
      child: WebViewWidget(controller: webViewController),
    );
  }
}
