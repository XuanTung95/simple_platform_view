import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_platform_view_example/android/clone_android_webview_platform.dart';
import 'package:simple_platform_view_example/ios/clone_webkit_webview_platform.dart';
import 'package:simple_platform_view_example/screen/expensive_widget.dart';
import 'package:simple_platform_view_example/screen/select_screen.dart';
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
      // CloneWebKitWebViewPlatform.registerWith();
    }
    webViewController = WebViewController();
    webViewController.loadRequest(Uri.parse("https://google.com"));
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clone WebView Screen"),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: WebViewWidget(controller: webViewController),
          ),
          const ExpensiveWidget(),
          Center(
            child: FloatingActionButton(
              heroTag: "webview",
              onPressed: () {
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

/*
class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.5;

    Paint red = Paint()
      ..color = Colors.red
      ..strokeWidth = 1;

    Paint blue = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1;

    for (int i = 0; i < 50; i++) {
      double y = 10.0 * i.toDouble();
      bool isRed = i % 10 == 0;
      bool isBlue = i % 5 == 0;
      canvas.drawLine(Offset(isRed ? 0: (isBlue ? size.width*1/3 : size.width*2/3), y), Offset(size.width, y), isRed ? red : ( isBlue ? blue : paint));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
*/