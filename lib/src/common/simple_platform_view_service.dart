// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:simple_platform_view/src/android/simple_platform_view_android.dart';
import 'package:simple_platform_view/src/common/simple_system_channels.dart';
import 'package:simple_platform_view/src/ios/simple_platform_view_ios.dart';

export 'dart:ui' show Offset, Size, TextDirection, VoidCallback;

export 'package:flutter/gestures.dart' show PointerEvent;

/// Provides access to the platform views service.
///
/// This service allows creating and controlling platform-specific views.
class SimplePlatformViewsService {
  SimplePlatformViewsService._() {
    SimpleSystemChannels.platformViewsChannel.setMethodCallHandler(_onMethodCall);
  }

  static final SimplePlatformViewsService instance = SimplePlatformViewsService._();

  int _nextPlatformViewId = 99999;

  int getNextPlatformViewId() {
    return _nextPlatformViewId++;
  }

  Future<void> _onMethodCall(MethodCall call) {
    switch (call.method) {
      case 'viewFocused':
        final int id = call.arguments as int;
        if (_focusCallbacks.containsKey(id)) {
          _focusCallbacks[id]!();
        }
        break;
      default:
        throw UnimplementedError("${call.method} was invoked but isn't implemented by PlatformViewsService");
    }
    return Future<void>.value();
  }

  /// Maps platform view IDs to focus callbacks.
  ///
  /// The callbacks are invoked when the platform view asks to be focused.
  final Map<int, VoidCallback> _focusCallbacks = <int, VoidCallback>{};

  /// {@template flutter.services.PlatformViewsService.initAndroidView}
  /// Creates a controller for a new Android view.
  ///
  /// `id` is an unused unique identifier generated with [platformViewsRegistry].
  ///
  /// `viewType` is the identifier of the Android view type to be created, a
  /// factory for this view type must have been registered on the platform side.
  /// Platform view factories are typically registered by plugin code.
  /// Plugins can register a platform view factory with
  /// [PlatformViewRegistry#registerViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewRegistry.html#registerViewFactory-java.lang.String-io.flutter.plugin.platform.PlatformViewFactory-).
  ///
  /// `creationParams` will be passed as the args argument of [PlatformViewFactory#create](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#create-android.content.Context-int-java.lang.Object-)
  ///
  /// `creationParamsCodec` is the codec used to encode `creationParams` before sending it to the
  /// platform side. It should match the codec passed to the constructor of [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#PlatformViewFactory-io.flutter.plugin.common.MessageCodec-).
  /// This is typically one of: [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec].
  ///
  /// `onFocus` is a callback that will be invoked when the Android View asks to get the
  /// input focus.
  ///
  /// The Android view will only be created after [AndroidViewController.setSize] is called for the
  /// first time.
  ///
  /// The `id, `viewType, and `layoutDirection` parameters must not be null.
  /// If `creationParams` is non null then `creationParamsCodec` must not be null.
  /// {@endtemplate}
  ///
  /// This attempts to use the newest and most efficient platform view
  /// implementation when possible. In cases where that is not supported, it
  /// falls back to using Virtual Display.
  static AndroidViewController initAndroidView({
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    VoidCallback? onFocus,
    bool useVirtualDisplay = false,
  }) {
    assert(creationParams == null || creationParamsCodec != null);

    final SimpleAndroidViewController controller = SimpleAndroidViewController(
      viewId: id,
      viewType: viewType,
      layoutDirection: layoutDirection,
      creationParams: creationParams,
      creationParamsCodec: creationParamsCodec,
      useVirtualDisplay: useVirtualDisplay,
    );

    if (onFocus != null) {
      instance._focusCallbacks[id] = onFocus;
    }
    return controller;
  }

  // TODO(amirh): reference the iOS plugin API for registering a UIView factory once it lands.
  /// This is work in progress, not yet ready to be used, and requires a custom engine build. Creates a controller for a new iOS UIView.
  ///
  /// `id` is an unused unique identifier generated with [platformViewsRegistry].
  ///
  /// `viewType` is the identifier of the iOS view type to be created, a
  /// factory for this view type must have been registered on the platform side.
  /// Platform view factories are typically registered by plugin code.
  ///
  /// `onFocus` is a callback that will be invoked when the UIKit view asks to
  /// get the input focus.
  /// The `id, `viewType, and `layoutDirection` parameters must not be null.
  /// If `creationParams` is non null then `creationParamsCodec` must not be null.
  static SimpleUiKitViewController initUiKitView({
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    VoidCallback? onFocus,
  }) {
    assert(creationParams == null || creationParamsCodec != null);
    // TODO(amirh): pass layoutDirection once the system channel supports it.
    if (onFocus != null) {
      instance._focusCallbacks[id] = onFocus;
    }
    return SimpleUiKitViewController(id: id,
        viewType: viewType,
        layoutDirection: layoutDirection,
        creationParams: creationParams,
        creationParamsCodec: creationParamsCodec,
    );
  }

  void removeFocusCallbacks(int viewId) {
    instance._focusCallbacks.remove(viewId);
  }
}