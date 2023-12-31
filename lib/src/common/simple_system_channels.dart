import 'package:flutter/services.dart';

class SimpleSystemChannels {
  /// A [MethodChannel] for controlling platform views.
  ///
  /// See also:
  ///
  ///  * [PlatformViewsService] for the available operations on this channel.
  static const MethodChannel platformViewsChannel = MethodChannel('tungpx/simple_platform_views');
}
