import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_platform_view_example/android/clone_android_webview_platform.dart';
import 'package:simple_platform_view_example/ios/clone_webkit_webview_platform.dart';
import 'package:simple_platform_view_example/screen/expensive_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CloneWebviewScreen extends StatefulWidget {
  const CloneWebviewScreen({Key? key}) : super(key: key);

  @override
  State<CloneWebviewScreen> createState() => _CloneWebviewScreenState();
}

class _CloneWebviewScreenState extends State<CloneWebviewScreen> {
  late WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    /// Replace WebViewPlatform.instance with the modified version
    if (Platform.isAndroid) {
      CloneAndroidWebViewPlatform.registerWith();
    } else if (Platform.isIOS) {
      CloneWebKitWebViewPlatform.registerWith();
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
        title: Text("Clone WebView Screen $count"),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: WebViewWidget(controller: webViewController),
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
