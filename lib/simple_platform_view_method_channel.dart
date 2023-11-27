import 'dart:io';

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

  @override
  Future<bool> isUsingImageView() async {
    if (Platform.isAndroid) {
      final res = await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('isUsingImageView');
      return res == true;
    }
    return false;
  }

  @override
  Future<void> convertToImageView() async {
    if (Platform.isAndroid) {
      await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('convertToImageView');
    }
  }

  @override
  Future<void> revertFromImageView() async {
    if (Platform.isAndroid) {
      await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('revertFromImageView');
    }
  }
}
