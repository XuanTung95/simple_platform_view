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

Enabling the visibility of the platform view involves the following steps:
- Convert from FlutterSurfaceView to FlutterImageView
- Clearing the content below the platform view

There is also need for a mechanism to forward touch events from Flutter view to platform views

## Consequences
Here are some considerations and consequences of using this plugin:

**Content Limitations**: Only content drawn on top of the platform view will be visible, the content below it will be cleared.

If the platform view is transparent, the absence of the underlying widget becomes noticeable.

However, if the platform view is opaque, there is no need to render the background content.

As a result, **this mode exclusively supports opaque platform views**

**FlutterImageView Limitations**:

This plugin use FlutterImageView to render the Flutter UI. Prior to Android 10, FlutterImageView copies 
each Flutter frame out of the graphic memory into main memory and then copied back to a GPU texture.
As this copy happens per frame, the performance of the entire Flutter UI may be impacted.
From Android 10, FlutterImageView use HardwareBuffer which have better performance.

**Hybrid Composition Combination**: Combining this mode with Hybrid Composition modes may result in unexpected behavior,
so use caution when integrating multiple composition modes simultaneously.

**View Hierarchy**: This plugin modifies the view hierarchy directly, this may lead to conflict with Flutter itself.

If you are using Virtual display mode or Hybrid composition texture layer mode without issues, you don't need this plugin.

If you are using Hybrid composition mode and facing performance issue, you can try this plugin.

## Getting Started

| Platform | Status   |
|----------|----------|
| Android  | 	✅    |
| iOS      | 	❌    |

#### Installation
Add the following dependency to your pubspec.yaml file:

```
dependencies:
  simple_platform_view:
```

### Usage
#### Android:

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

**iOS is not supported**

**Used by other plugins**:

| Plugins                       |
| ------------------------------|
| [simple_google_maps_flutter](https://pub.dev/packages/simple_google_maps_flutter) |
