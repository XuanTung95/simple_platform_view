# simple_platform_view

A Flutter plugin to integrate platform views directly into the Flutter view hierarchy, aiming to provide the best possible performance.

## Design
To achieve good performance, this plugin follows a specific design approach:
### Rendering:

The Flutter UI is rendered into a single view.

Keep the rasterization task on the raster thread.

This approach provide better performance than hybrid composition mode, which render flutter ui into multiple views and move the rasterization task to platform thread.

Basically, this plugin continues to render the Flutter UI as if there was no platform view.

### Platform view:

Platform view will be rendered in the same way as a native app does.

After creating the platform view, it is positioned behind the FlutterView.
Because the platform view is obscured by the Flutter view, there needs to be a mechanism for it to be visible.

Enabling the visibility of the platform view involves the following steps:
- Making the Flutter view transparent
- Clearing the content below the platform view

There is also need for a mechanism to forward touch events from Flutter view to platform views

## Consequences
Here are some considerations and consequences of using this plugin:

**Content Limitations**: Only content drawn on top of the platform view will be visible, the content below it will be cleared.

If the platform view is transparent, the absence of the underlying widget becomes noticeable.

However, if the platform view is opaque, there is no need to render the background content.

As a result, **this mode exclusively supports opaque platform views**

**Position Synchronization**: Moving the platform view can lead to synchronization issues.

The position of the platform view is updated through method channels, but there is no guarantee
that its position will align perfectly with the updates of the Flutter UI.

Therefore, it is recommended to use this mode with fixed-position platform views, such as
a map in a mapping app or a webview screen. **Do not use it inside a scroll view**.

**Hybrid Composition Combination**: Combining this mode with Hybrid Composition modes may result in unexpected behavior,
so use caution when integrating multiple composition modes simultaneously.

**View Hierarchy**: This plugin modifies the view hierarchy directly, this may lead to conflict with Flutter itself.

If you are using Virtual display mode or Hybrid composition texture layer mode without issues, you don't need this plugin.

If you are using Hybrid composition mode and facing performance issue, you can try this plugin.

## Getting Started

| Platform | Status     |
|----------|------------|
| Android  | 	✅     |
| iOS      | 	✅     |

#### Installation
Add the following dependency to your pubspec.yaml file:

```
dependencies:
  simple_platform_view:
```

### Usage
#### Android:
**Make FlutterView transparent (required)**

Add following code to MainActivity.java:
  ```java
    import androidx.annotation.NonNull;
    import io.flutter.embedding.android.FlutterActivity;
    import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode;

    public class MainActivity extends FlutterActivity {

        @NonNull
        @Override
        protected BackgroundMode getBackgroundMode() {
            return BackgroundMode.transparent;
        }
    }
  ```

To use this plugin, just replace `AndroidView` widget with `SimpleAndroidView`:

  ```dart
    import 'package:simple_platform_view/simple_platform_view.dart';

    @override
    Widget build(BuildContext context) {
      return SimpleAndroidView(
        viewType: "your_view_type",
        onPlatformViewCreated: (id) {
          // your callback
        },
        creationParams: {},
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  ```

If you are trying to use this with other plugin, clone their plugin and replace the implementation with `SimpleAndroidView`. See Example for more detail.

| Demo                       |
| ------------------------------|
| <img src="https://raw.githubusercontent.com/XuanTung95/simple_platform_view/master/images/demo_video.gif" width="220" height="450"> |

| View hierarchy                        | Empty transparent platform view                        |
| ------------------------------| ------------------------------|
| <img src="https://raw.githubusercontent.com/XuanTung95/simple_platform_view/master/images/Screenshot_2.png" width="200" height="300"> | <img src="https://raw.githubusercontent.com/XuanTung95/simple_platform_view/master/images/Screenshot_1.jpg" width="200" height="400">  |

#### iOS:

**Register PlatformViewFactory**

If you are developing your own plugin, use `SimplePlatformViewPlugin.registerViewFactory` to register your platform view into SimplePlatformViewPlugin
  ```swift
    public static func register(with registrar: FlutterPluginRegistrar) {
        SimplePlatformViewPlugin.registerViewFactory(
            MyPlatformViewFactory(messenger: registrar.messenger()),
            withId: "my_view_type",
            gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyEager
        )
    }
  ```

If you want to register automatically or use platform view from other plugins:
  ```swift
import simple_platform_view;

@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let fakeRegistry = SimplePlatformViewPlugin.createFakeFlutterPluginRegistry(realPluginRegistry: self);
        GeneratedPluginRegistrant.register(with: fakeRegistry);
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
  ```

Replace `UiKitView` widget with `SimpleUiKitView`:

  ```dart
  Widget build(BuildContext context) {
    return SimpleUiKitView(
      viewType: 'my_view_type',
      onPlatformViewCreated: onPlatformViewCreated,
      gestureRecognizers: gestureRecognizers,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
  ```

**Note**: there is a weird bug when using this plugin on certain iPhone devices like iPhone XS or iPhone XR. 
While the cellular signal bar (the icon on the status bar) is animating, the frame rate is drop to 20fps. 
It returns to 60fps once the animation is complete or when the icon is not displayed ([#115036](https://github.com/flutter/flutter/issues/115036)).

**Change the background color**
If you want to change the background color of FlutterView:

  ```dart
  import 'package:simple_platform_view/simple_platform_view.dart';
  void changeBackgroundColor() {
    SimplePlatformView.setBackgroundColor(Colors.red);
  }
  ```

**Used by other plugins**:

| Plugins                       |
| ------------------------------|
| [simple_google_maps_flutter](https://pub.dev/packages/simple_google_maps_flutter) |
