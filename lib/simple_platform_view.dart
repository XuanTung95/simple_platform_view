
import 'simple_platform_view_platform_interface.dart';

class SimplePlatformView {
  Future<String?> getPlatformVersion() {
    return SimplePlatformViewPlatform.instance.getPlatformVersion();
  }
}
