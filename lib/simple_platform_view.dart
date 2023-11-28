import 'dart:ui';
import 'package:simple_platform_view/simple_platform_view_platform_interface.dart';
import 'package:simple_platform_view/src/common/surface_mode.dart';
export 'package:simple_platform_view/src/common/surface_mode.dart';
export 'src/android/simple_platform_view_android.dart';
export 'src/android/simple_platform_view_scroll_behavior.dart';

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

  /// Get SurfaceMode
  static SurfaceMode getSurfaceMode() {
    return SimplePlatformViewPlatform.instance.getSurfaceMode();
  }

  /// Get SurfaceMode
  /// - multipleSurface: switch between FlutterSurfaceView/FlutterImageView if possible
  /// - singleSurface: only uses FlutterImageView
  static Future<void> setSurfaceMode(SurfaceMode mode) {
    return SimplePlatformViewPlatform.instance.setSurfaceMode(mode);
  }

}