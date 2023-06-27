import 'dart:ui';
import 'dart:io';
import 'package:simple_platform_view/simple_platform_view_platform_interface.dart';
export 'src/android/simple_platform_view_android.dart';
export 'src/ios/simple_platform_view_ios.dart';

class SimplePlatformView {

  /// Set background color for FlutterView
  static Future<void> setBackgroundColor(Color color) {
    return SimplePlatformViewPlatform.instance.setBackgroundColor(color);
  }

  /// Clear all platform views in the view hierarchy after hot restart.
  /// For ios only.
  static Future<void> restart() {
    if (Platform.isAndroid) {
      return Future.value();
    }
    return SimplePlatformViewPlatform.instance.restart();
  }
}