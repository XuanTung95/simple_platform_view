// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_platform_view/simple_platform_view.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_android/src/android_proxy.dart';
import 'package:webview_flutter_android/src/android_webview.dart' as android_webview;
import 'package:webview_flutter_android/src/instance_manager.dart';
import 'package:webview_flutter_android/src/platform_views_service_proxy.dart';
import 'package:webview_flutter_android/src/weak_reference_utils.dart';

/// Implementation of [WebViewPlatform] using the WebKit API.
class CloneAndroidWebViewPlatform extends WebViewPlatform {
  /// Registers this class as the default instance of [WebViewPlatform].
  static void registerWith() {
    if (Platform.isAndroid) {
      WebViewPlatform.instance = CloneAndroidWebViewPlatform.instance;
    }
  }

  static final CloneAndroidWebViewPlatform _instance = CloneAndroidWebViewPlatform._();
  static CloneAndroidWebViewPlatform get instance {
    return _instance;
  }

  CloneAndroidWebViewPlatform._();

  @override
  CloneAndroidWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params,
      ) {
    return CloneAndroidWebViewController(params);
  }

  @override
  AndroidNavigationDelegate createPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params,
      ) {
    return AndroidNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
      PlatformWebViewWidgetCreationParams params,
      ) {
    return CloneAndroidWebViewWidget(params);
  }

  @override
  AndroidWebViewCookieManager createPlatformCookieManager(
      PlatformWebViewCookieManagerCreationParams params,
      ) {
    return AndroidWebViewCookieManager(params);
  }
}

/// An implementation of [PlatformWebViewWidget] with the Android WebView API.
class CloneAndroidWebViewWidget extends PlatformWebViewWidget {
  /// Constructs a [WebKitWebViewWidget].
  CloneAndroidWebViewWidget(PlatformWebViewWidgetCreationParams params)
      : super.implementation(
    params is AndroidWebViewWidgetCreationParams
        ? params
        : AndroidWebViewWidgetCreationParams
        .fromPlatformWebViewWidgetCreationParams(params),
  );

  AndroidWebViewWidgetCreationParams get _androidParams =>
      params as AndroidWebViewWidgetCreationParams;

  @override
  Widget build(BuildContext context) {
    return SimpleAndroidView(
      key: _androidParams.key,
      viewType: 'plugins.flutter.io/webview',
      onPlatformViewCreated: (int id) {
      },
      creationParams: _androidParams.instanceManager.getIdentifier(
        (_androidParams.controller as CloneAndroidWebViewController)._webView),
      gestureRecognizers: _androidParams.gestureRecognizers,
      creationParamsCodec: const StandardMessageCodec(),
    );
    PlatformViewLink;
    // return PlatformViewLink(
    //   key: _androidParams.key,
    //   viewType: 'plugins.flutter.io/webview',
    //   surfaceFactory: (
    //       BuildContext context,
    //       PlatformViewController controller,
    //       ) {
    //     return AndroidViewSurface(
    //       controller: controller as AndroidViewController,
    //       gestureRecognizers: _androidParams.gestureRecognizers,
    //       hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    //     );
    //   },
    //   onCreatePlatformView: (PlatformViewCreationParams params) {
    //     return _initAndroidView(
    //       params,
    //       displayWithHybridComposition:
    //       _androidParams.displayWithHybridComposition,
    //     )
    //       ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
    //       ..create();
    //   },
    // );
  }

  // AndroidViewController _initAndroidView(
  //     PlatformViewCreationParams params, {
  //       required bool displayWithHybridComposition,
  //     }) {
  //   if (displayWithHybridComposition) {
  //     return _androidParams.platformViewsServiceProxy.initExpensiveAndroidView(
  //       id: params.id,
  //       viewType: 'plugins.flutter.io/webview',
  //       layoutDirection: _androidParams.layoutDirection,
  //       creationParams: _androidParams.instanceManager.getIdentifier(
  //           (_androidParams.controller as AndroidWebViewController)._webView),
  //       creationParamsCodec: const StandardMessageCodec(),
  //     );
  //   } else {
  //     return _androidParams.platformViewsServiceProxy.initSurfaceAndroidView(
  //       id: params.id,
  //       viewType: 'plugins.flutter.io/webview',
  //       layoutDirection: _androidParams.layoutDirection,
  //       creationParams: _androidParams.instanceManager.getIdentifier(
  //           (_androidParams.controller as AndroidWebViewController)._webView),
  //       creationParamsCodec: const StandardMessageCodec(),
  //     );
  //   }
  // }
}

/// Implementation of the [PlatformWebViewController] with the Android WebView API.
class CloneAndroidWebViewController extends PlatformWebViewController {
  /// Creates a new [AndroidWebViewCookieManager].
  CloneAndroidWebViewController(PlatformWebViewControllerCreationParams params)
      : super.implementation(params is AndroidWebViewControllerCreationParams
      ? params
      : AndroidWebViewControllerCreationParams
      .fromPlatformWebViewControllerCreationParams(params)) {
    _webView.settings.setDomStorageEnabled(true);
    _webView.settings.setJavaScriptCanOpenWindowsAutomatically(true);
    _webView.settings.setSupportMultipleWindows(true);
    _webView.settings.setLoadWithOverviewMode(true);
    _webView.settings.setUseWideViewPort(true);
    _webView.settings.setDisplayZoomControls(false);
    _webView.settings.setBuiltInZoomControls(true);

    _webView.setWebChromeClient(_webChromeClient);
  }

  AndroidWebViewControllerCreationParams get _androidWebViewParams =>
      params as AndroidWebViewControllerCreationParams;

  /// The native [android_webview.WebView] being controlled.
  late final android_webview.WebView _webView =
  _androidWebViewParams.androidWebViewProxy.createAndroidWebView();

  late final android_webview.WebChromeClient _webChromeClient =
  _androidWebViewParams.androidWebViewProxy.createAndroidWebChromeClient(
    onProgressChanged: withWeakReferenceTo(this,
            (WeakReference<CloneAndroidWebViewController> weakReference) {
          return (android_webview.WebView webView, int progress) {
          };
        }),
    onGeolocationPermissionsShowPrompt: withWeakReferenceTo(this,
            (WeakReference<CloneAndroidWebViewController> weakReference) {
          return (String origin,
              android_webview.GeolocationPermissionsCallback callback) async {
            final OnGeolocationPermissionsShowPrompt? onShowPrompt =
                weakReference.target?._onGeolocationPermissionsShowPrompt;
            if (onShowPrompt != null) {
              final GeolocationPermissionsResponse response = await onShowPrompt(
                GeolocationPermissionsRequestParams(origin: origin),
              );
              callback.invoke(origin, response.allow, response.retain);
            } else {
              // default don't allow
              callback.invoke(origin, false, false);
            }
          };
        }),
    onGeolocationPermissionsHidePrompt: withWeakReferenceTo(this,
            (WeakReference<CloneAndroidWebViewController> weakReference) {
          return (android_webview.WebChromeClient instance) {
            final OnGeolocationPermissionsHidePrompt? onHidePrompt =
                weakReference.target?._onGeolocationPermissionsHidePrompt;
            if (onHidePrompt != null) {
              onHidePrompt();
            }
          };
        }),
    onShowFileChooser: withWeakReferenceTo(
      this,
          (WeakReference<CloneAndroidWebViewController> weakReference) {
        return (android_webview.WebView webView,
            android_webview.FileChooserParams params) async {
          if (weakReference.target?._onShowFileSelectorCallback != null) {
          }
          return <String>[];
        };
      },
    ),
    onPermissionRequest: withWeakReferenceTo(
      this,
          (WeakReference<CloneAndroidWebViewController> weakReference) {
        return (_, android_webview.PermissionRequest request) async {
          final void Function(PlatformWebViewPermissionRequest)? callback =
              weakReference.target?._onPermissionRequestCallback;
          if (callback == null) {
            return request.deny();
          } else {
            final Set<WebViewPermissionResourceType> types = request.resources
                .map<WebViewPermissionResourceType?>((String type) {
              switch (type) {
                case android_webview.PermissionRequest.videoCapture:
                  return WebViewPermissionResourceType.camera;
                case android_webview.PermissionRequest.audioCapture:
                  return WebViewPermissionResourceType.microphone;
                case android_webview.PermissionRequest.midiSysex:
                  return AndroidWebViewPermissionResourceType.midiSysex;
                case android_webview.PermissionRequest.protectedMediaId:
                  return AndroidWebViewPermissionResourceType
                      .protectedMediaId;
              }

              // Type not supported.
              return null;
            })
                .whereType<WebViewPermissionResourceType>()
                .toSet();

            // If the request didn't contain any permissions recognized by the
            // implementation, deny by default.
            if (types.isEmpty) {
              return request.deny();
            }
          }
        };
      },
    ),
  );

  /// The native [android_webview.FlutterAssetManager] allows managing assets.
  late final android_webview.FlutterAssetManager _flutterAssetManager =
  _androidWebViewParams.androidWebViewProxy.createFlutterAssetManager();

  final Map<String, AndroidJavaScriptChannelParams> _javaScriptChannelParams =
  <String, AndroidJavaScriptChannelParams>{};

  AndroidNavigationDelegate? _currentNavigationDelegate;

  Future<List<String>> Function(FileSelectorParams)?
  _onShowFileSelectorCallback;

  OnGeolocationPermissionsShowPrompt? _onGeolocationPermissionsShowPrompt;

  OnGeolocationPermissionsHidePrompt? _onGeolocationPermissionsHidePrompt;

  void Function(PlatformWebViewPermissionRequest)? _onPermissionRequestCallback;

  /// Whether to enable the platform's webview content debugging tools.
  ///
  /// Defaults to false.
  static Future<void> enableDebugging(
      bool enabled, {
        @visibleForTesting
        AndroidWebViewProxy webViewProxy = const AndroidWebViewProxy(),
      }) {
    return webViewProxy.setWebContentsDebuggingEnabled(enabled);
  }

  /// Identifier used to retrieve the underlying native `WKWebView`.
  ///
  /// This is typically used by other plugins to retrieve the native `WebView`
  /// from an `InstanceManager`.
  ///
  /// See Java method `WebViewFlutterPlugin.getWebView`.
  int get webViewIdentifier =>
      // ignore: invalid_use_of_visible_for_testing_member
  android_webview.WebView.api.instanceManager.getIdentifier(_webView)!;

  @override
  Future<void> loadFile(
      String absoluteFilePath,
      ) {
    final String url = absoluteFilePath.startsWith('file://')
        ? absoluteFilePath
        : Uri.file(absoluteFilePath).toString();

    _webView.settings.setAllowFileAccess(true);
    return _webView.loadUrl(url, <String, String>{});
  }

  @override
  Future<void> loadFlutterAsset(
      String key,
      ) async {
    final String assetFilePath =
    await _flutterAssetManager.getAssetFilePathByName(key);
    final List<String> pathElements = assetFilePath.split('/');
    final String fileName = pathElements.removeLast();
    final List<String?> paths =
    await _flutterAssetManager.list(pathElements.join('/'));

    if (!paths.contains(fileName)) {
      throw ArgumentError(
        'Asset for key "$key" not found.',
        'key',
      );
    }

    return _webView.loadUrl(
      Uri.file('/android_asset/$assetFilePath').toString(),
      <String, String>{},
    );
  }

  @override
  Future<void> loadHtmlString(
      String html, {
        String? baseUrl,
      }) {
    return _webView.loadDataWithBaseUrl(
      baseUrl: baseUrl,
      data: html,
      mimeType: 'text/html',
    );
  }

  @override
  Future<void> loadRequest(
      LoadRequestParams params,
      ) {
    if (!params.uri.hasScheme) {
      throw ArgumentError('WebViewRequest#uri is required to have a scheme.');
    }
    switch (params.method) {
      case LoadRequestMethod.get:
        return _webView.loadUrl(params.uri.toString(), params.headers);
      case LoadRequestMethod.post:
        return _webView.postUrl(
            params.uri.toString(), params.body ?? Uint8List(0));
    }
    // The enum comes from a different package, which could get a new value at
    // any time, so a fallback case is necessary. Since there is no reasonable
    // default behavior, throw to alert the client that they need an updated
    // version. This is deliberately outside the switch rather than a `default`
    // so that the linter will flag the switch as needing an update.
    // ignore: dead_code
    throw UnimplementedError(
        'This version of `AndroidWebViewController` currently has no '
            'implementation for HTTP method ${params.method.serialize()} in '
            'loadRequest.');
  }

  @override
  Future<String?> currentUrl() => _webView.getUrl();

  @override
  Future<bool> canGoBack() => _webView.canGoBack();

  @override
  Future<bool> canGoForward() => _webView.canGoForward();

  @override
  Future<void> goBack() => _webView.goBack();

  @override
  Future<void> goForward() => _webView.goForward();

  @override
  Future<void> reload() => _webView.reload();

  @override
  Future<void> clearCache() => _webView.clearCache(true);

  @override
  Future<void> clearLocalStorage() =>
      _androidWebViewParams.androidWebStorage.deleteAllData();

  @override
  Future<void> setPlatformNavigationDelegate(
      covariant AndroidNavigationDelegate handler) async {
    _currentNavigationDelegate = handler;
    handler.setOnLoadRequest(loadRequest);
    _webView.setWebViewClient(handler.androidWebViewClient);
    _webView.setDownloadListener(handler.androidDownloadListener);
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    return _webView.evaluateJavascript(javaScript);
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    final String? result = await _webView.evaluateJavascript(javaScript);

    if (result == null) {
      return '';
    } else if (result == 'true') {
      return true;
    } else if (result == 'false') {
      return false;
    }

    return num.tryParse(result) ?? result;
  }

  @override
  Future<void> addJavaScriptChannel(
      JavaScriptChannelParams javaScriptChannelParams,
      ) async {
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
  }

  @override
  Future<String?> getTitle() => _webView.getTitle();

  @override
  Future<void> scrollTo(int x, int y) => _webView.scrollTo(x, y);

  @override
  Future<void> scrollBy(int x, int y) => _webView.scrollBy(x, y);

  @override
  Future<Offset> getScrollPosition() {
    return _webView.getScrollPosition();
  }

  @override
  Future<void> enableZoom(bool enabled) =>
      _webView.settings.setSupportZoom(enabled);

  @override
  Future<void> setBackgroundColor(Color color) =>
      _webView.setBackgroundColor(color);

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) =>
      _webView.settings
          .setJavaScriptEnabled(javaScriptMode == JavaScriptMode.unrestricted);

  @override
  Future<void> setUserAgent(String? userAgent) =>
      _webView.settings.setUserAgentString(userAgent);

  /// Sets the restrictions that apply on automatic media playback.
  Future<void> setMediaPlaybackRequiresUserGesture(bool require) {
    return _webView.settings.setMediaPlaybackRequiresUserGesture(require);
  }

  /// Sets the text zoom of the page in percent.
  ///
  /// The default is 100.
  Future<void> setTextZoom(int textZoom) =>
      _webView.settings.setTextZoom(textZoom);

  /// Sets the callback that is invoked when the client should show a file
  /// selector.
  Future<void> setOnShowFileSelector(
      Future<List<String>> Function(FileSelectorParams params)?
      onShowFileSelector,
      ) {
    _onShowFileSelectorCallback = onShowFileSelector;
    return _webChromeClient.setSynchronousReturnValueForOnShowFileChooser(
      onShowFileSelector != null,
    );
  }

  /// Sets a callback that notifies the host application that web content is
  /// requesting permission to access the specified resources.
  ///
  /// Only invoked on Android versions 21+.
  @override
  Future<void> setOnPlatformPermissionRequest(
      void Function(
          PlatformWebViewPermissionRequest request,
          ) onPermissionRequest,
      ) async {
    _onPermissionRequestCallback = onPermissionRequest;
  }

  /// Sets the callback that is invoked when the client request handle geolocation permissions.
  ///
  /// Param [onShowPrompt] notifies the host application that web content from the specified origin is attempting to use the Geolocation API,
  /// but no permission state is currently set for that origin.
  ///
  /// The host application should invoke the specified callback with the desired permission state.
  /// See GeolocationPermissions for details.
  ///
  /// Note that for applications targeting Android N and later SDKs (API level > Build.VERSION_CODES.M)
  /// this method is only called for requests originating from secure origins such as https.
  /// On non-secure origins geolocation requests are automatically denied.
  ///
  /// Param [onHidePrompt] notifies the host application that a request for Geolocation permissions,
  /// made with a previous call to onGeolocationPermissionsShowPrompt() has been canceled.
  /// Any related UI should therefore be hidden.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient#onGeolocationPermissionsShowPrompt(java.lang.String,%20android.webkit.GeolocationPermissions.Callback)
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient#onGeolocationPermissionsHidePrompt()
  Future<void> setGeolocationPermissionsPromptCallbacks({
    OnGeolocationPermissionsShowPrompt? onShowPrompt,
    OnGeolocationPermissionsHidePrompt? onHidePrompt,
  }) async {
    _onGeolocationPermissionsShowPrompt = onShowPrompt;
    _onGeolocationPermissionsHidePrompt = onHidePrompt;
  }
}