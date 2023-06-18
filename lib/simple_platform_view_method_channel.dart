import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simple_platform_view_platform_interface.dart';

/// An implementation of [SimplePlatformViewPlatform] that uses method channels.
class MethodChannelSimplePlatformView extends SimplePlatformViewPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('simple_platform_view');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
