import 'dart:ui';
import 'package:simple_platform_view/simple_platform_view_platform_interface.dart';
export 'src/android/simple_platform_view_android.dart';

class SimplePlatformView {

  /// Set background color for FlutterView
  static Future<void> setBackgroundColor(Color color) {
    return SimplePlatformViewPlatform.instance.setBackgroundColor(color);
  }

  /// Clear all platform views in the view hierarchy after hot restart.
  /// For ios only.
  // static Future<void> restart() {
  //   if (Platform.isAndroid) {
  //     return Future.value();
  //   }
  //   return SimplePlatformViewPlatform.instance.restart();
  // }

  static Future<bool> isUsingImageView() {
    return SimplePlatformViewPlatform.instance.isUsingImageView();
  }

  static Future<void> convertToImageView() {
    return SimplePlatformViewPlatform.instance.convertToImageView();
  }

  static Future<void> revertFromImageView() {
    return SimplePlatformViewPlatform.instance.revertFromImageView();
  }

}