import 'package:flutter_test/flutter_test.dart';
import 'package:simple_platform_view/simple_platform_view.dart';
import 'package:simple_platform_view/simple_platform_view_platform_interface.dart';
import 'package:simple_platform_view/simple_platform_view_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSimplePlatformViewPlatform
    with MockPlatformInterfaceMixin
    implements SimplePlatformViewPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SimplePlatformViewPlatform initialPlatform = SimplePlatformViewPlatform.instance;

  test('$MethodChannelSimplePlatformView is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSimplePlatformView>());
  });

  test('getPlatformVersion', () async {
    SimplePlatformView simplePlatformViewPlugin = SimplePlatformView();
    MockSimplePlatformViewPlatform fakePlatform = MockSimplePlatformViewPlatform();
    SimplePlatformViewPlatform.instance = fakePlatform;

    expect(await simplePlatformViewPlugin.getPlatformVersion(), '42');
  });
}
