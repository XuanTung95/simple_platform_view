import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simple_platform_view_platform_interface.dart';
import 'src/common/simple_system_channels.dart';

/// An implementation of [SimplePlatformViewPlatform] that uses method channels.
class MethodChannelSimplePlatformView extends SimplePlatformViewPlatform {

  @override
  Future<void> setBackgroundColor(Color color) async {
    await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('setBackgroundColor', {'color': color.value});
  }

  @override
  Future<void> restart() async {
    await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('hotRestart');
  }
}
