import 'dart:ui';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:simple_platform_view/src/common/surface_mode.dart';

import 'simple_platform_view_method_channel.dart';

abstract class SimplePlatformViewPlatform extends PlatformInterface {
  /// Constructs a SimplePlatformViewPlatform.
  SimplePlatformViewPlatform() : super(token: _token);

  static final Object _token = Object();

  static SimplePlatformViewPlatform _instance = MethodChannelSimplePlatformView();

  /// The default instance of [SimplePlatformViewPlatform] to use.
  ///
  /// Defaults to [MethodChannelSimplePlatformView].
  static SimplePlatformViewPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SimplePlatformViewPlatform] when
  /// they register themselves.
  static set instance(SimplePlatformViewPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setBackgroundColor(Color color) {
    throw UnimplementedError('setBackgroundColor() has not been implemented.');
  }

  Future<void> restart() {
    throw UnimplementedError('restart() has not been implemented.');
  }

  SurfaceMode getSurfaceMode() {
    throw UnimplementedError('getSurfaceMode() has not been implemented.');
  }

  Future<void> setSurfaceMode(SurfaceMode mode) {
    throw UnimplementedError('setSurfaceMode() has not been implemented.');
  }

}
