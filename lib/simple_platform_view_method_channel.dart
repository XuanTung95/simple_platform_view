import 'dart:io';

import 'package:flutter/services.dart';
import 'package:simple_platform_view/src/common/surface_mode.dart';

import 'simple_platform_view_platform_interface.dart';
import 'src/common/simple_system_channels.dart';

/// An implementation of [SimplePlatformViewPlatform] that uses method channels.
class MethodChannelSimplePlatformView extends SimplePlatformViewPlatform {

  SurfaceMode _surfaceMode = SurfaceMode.multipleSurface;

  @override
  Future<void> setBackgroundColor(Color color) async {
    await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('setBackgroundColor', {'color': color.value});
  }

  @override
  Future<void> restart() async {
    await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('hotRestart');
  }

  @override
  SurfaceMode getSurfaceMode() {
    return _surfaceMode;
  }

  @override
  Future<void> setSurfaceMode(SurfaceMode mode) async {
    if (_surfaceMode == mode) {
      return;
    }
    _surfaceMode = mode;
    int modeInt;
    switch (mode) {
      case SurfaceMode.multipleSurface:
        modeInt = 0;
        break;
      case SurfaceMode.singleSurface:
        modeInt = 1;
        break;
    }
    await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('setSurfaceMode', modeInt);
  }
}
