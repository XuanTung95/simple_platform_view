
import 'dart:ui';
import 'package:simple_platform_view/simple_platform_view_platform_interface.dart';
export 'src/android/simple_platform_view_android.dart';

class SimplePlatformView {

  /// Set background color for FlutterView
  static Future<void> setBackgroundColor(Color color) {
    return SimplePlatformViewPlatform.instance.setBackgroundColor(color);
  }

}