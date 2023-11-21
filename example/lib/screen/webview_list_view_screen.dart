import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_platform_view_example/android/clone_android_webview_platform.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewListViewScreen extends StatefulWidget {
  const WebViewListViewScreen({super.key});

  @override
  State<WebViewListViewScreen> createState() => _WebViewListViewScreenState();
}

class _WebViewListViewScreenState extends State<WebViewListViewScreen> {

  late WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    /// Replace WebViewPlatform.instance with the modified version
    if (Platform.isAndroid) {
      CloneAndroidWebViewPlatform.registerWith();
    } else if (Platform.isIOS) {
      // CloneWebKitWebViewPlatform.registerWith();
    }
    webViewController = WebViewController();
    webViewController.loadRequest(Uri.parse("https://google.com"));
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        bgColor = Colors.orange;
      });
    });
  }

  Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
      ),
      body: CustomScrollView(
        slivers: [SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 15) {
                return SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: WebViewWidget(controller: webViewController),
                );
              }
              return const SizedBox(
                  height: 100,
                  child: Placeholder(),
              );
            },
          childCount: 120,
        ))],
      ),
    );
  }
}
