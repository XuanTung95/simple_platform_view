import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simple_platform_view_platform_interface.dart';

/// An implementation of [SimplePlatformViewPlatform] that uses method channels.
class MethodChannelSimplePlatformView extends SimplePlatformViewPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tungpx/simple_platform_views_global');

  @override
  Future<void> setBackgroundColor(Color color) async {
    await methodChannel.invokeMethod<dynamic>('setBackgroundColor', {'color': color.value});
  }
}
