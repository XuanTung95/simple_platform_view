import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_platform_view/src/common/clear_background_painter.dart';
import 'package:simple_platform_view/src/common/simple_platform_view_service.dart';
import 'package:simple_platform_view/src/common/simple_system_channels.dart';

/// Embeds an Android view in the Widget hierarchy.
///
/// Requires Android API level 23 or greater.
///
/// Embedding Android views is an expensive operation and should be avoided when a Flutter
/// equivalent is possible.
///
/// The embedded Android view is painted just like any other Flutter widget and transformations
/// apply to it as well.
///
/// {@template flutter.widgets.AndroidView.layout}
/// The widget fills all available space, the parent of this object must provide bounded layout
/// constraints.
/// {@endtemplate}
///
/// {@template flutter.widgets.AndroidView.gestures}
/// The widget participates in Flutter's gesture arenas, and dispatches touch events to the
/// platform view iff it won the arena. Specific gestures that should be dispatched to the platform
/// view can be specified in the `gestureRecognizers` constructor parameter. If
/// the set of gesture recognizers is empty, a gesture will be dispatched to the platform
/// view iff it was not claimed by any other gesture recognizer.
/// {@endtemplate}
///
/// The Android view object is created using a [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html).
/// Plugins can register platform view factories with [PlatformViewRegistry#registerViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewRegistry.html#registerViewFactory-java.lang.String-io.flutter.plugin.platform.PlatformViewFactory-).
///
/// Registration is typically done in the plugin's registerWith method, e.g:
///
/// ```java
///   public static void registerWith(Registrar registrar) {
///     registrar.platformViewRegistry().registerViewFactory("webview", WebViewFactory(registrar.messenger()));
///   }
/// ```
///
/// {@template flutter.widgets.AndroidView.lifetime}
/// The platform view's lifetime is the same as the lifetime of the [State] object for this widget.
/// When the [State] is disposed the platform view (and auxiliary resources) are lazily
/// released (some resources are immediately released and some by platform garbage collector).
/// A stateful widget's state is disposed when the widget is removed from the tree or when it is
/// moved within the tree. If the stateful widget has a key and it's only moved relative to its siblings,
/// or it has a [GlobalKey] and it's moved within the tree, it will not be disposed.
/// {@endtemplate}
class SimpleAndroidView extends StatefulWidget {
  /// Creates a widget that embeds an Android view.
  ///
  /// {@template flutter.widgets.AndroidView.constructorArgs}
  /// The `viewType` and `hitTestBehavior` parameters must not be null.
  /// If `creationParams` is not null then `creationParamsCodec` must not be null.
  /// {@endtemplate}
  const SimpleAndroidView({
    super.key,
    required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.gestureRecognizers,
    this.creationParams,
    this.creationParamsCodec,
    this.clipBehavior = Clip.hardEdge,
    this.useVirtualDisplay = false,
  }) : assert(creationParams == null || creationParamsCodec != null);

  /// The unique identifier for Android view type to be embedded by this widget.
  ///
  /// A [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html)
  /// for this type must have been registered.
  ///
  /// See also:
  ///
  ///  * [SimpleAndroidView] for an example of registering a platform view factory.
  final String viewType;

  /// {@template flutter.widgets.AndroidView.onPlatformViewCreated}
  /// Callback to invoke after the platform view has been created.
  ///
  /// May be null.
  /// {@endtemplate}
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  /// {@template flutter.widgets.AndroidView.hitTestBehavior}
  /// How this widget should behave during hit testing.
  ///
  /// This defaults to [PlatformViewHitTestBehavior.opaque].
  /// {@endtemplate}
  final PlatformViewHitTestBehavior hitTestBehavior;

  /// {@template flutter.widgets.AndroidView.layoutDirection}
  /// The text direction to use for the embedded view.
  ///
  /// If this is null, the ambient [Directionality] is used instead.
  /// {@endtemplate}
  final TextDirection? layoutDirection;

  /// Which gestures should be forwarded to the Android view.
  ///
  /// {@template flutter.widgets.AndroidView.gestureRecognizers.descHead}
  /// The gesture recognizers built by factories in this set participate in the gesture arena for
  /// each pointer that was put down on the widget. If any of these recognizers win the
  /// gesture arena, the entire pointer event sequence starting from the pointer down event
  /// will be dispatched to the platform view.
  ///
  /// When null, an empty set of gesture recognizer factories is used, in which case a pointer event sequence
  /// will only be dispatched to the platform view if no other member of the arena claimed it.
  /// {@endtemplate}
  ///
  /// For example, with the following setup vertical drags will not be dispatched to the Android
  /// view as the vertical drag gesture is claimed by the parent [GestureDetector].
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails d) {},
  ///   child: const AndroidView(
  ///     viewType: 'webview',
  ///   ),
  /// )
  /// ```
  ///
  /// To get the [SimpleAndroidView] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: AndroidView(
  ///       viewType: 'webview',
  ///       gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
  ///         Factory<OneSequenceGestureRecognizer>(
  ///           () => EagerGestureRecognizer(),
  ///         ),
  ///       },
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// {@template flutter.widgets.AndroidView.gestureRecognizers.descFoot}
  /// A platform view can be configured to consume all pointers that were put
  /// down in its bounds by passing a factory for an [EagerGestureRecognizer] in
  /// [gestureRecognizers]. [EagerGestureRecognizer] is a special gesture
  /// recognizer that immediately claims the gesture after a pointer down event.
  ///
  /// The [gestureRecognizers] property must not contain more than one factory
  /// with the same [Factory.type].
  ///
  /// Changing [gestureRecognizers] results in rejection of any active gesture
  /// arenas (if the platform view is actively participating in an arena).
  /// {@endtemplate}
  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// Passed as the args argument of [PlatformViewFactory#create](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#create-android.content.Context-int-java.lang.Object-)
  ///
  /// This can be used by plugins to pass constructor parameters to the embedded Android view.
  final dynamic creationParams;

  /// The codec used to encode `creationParams` before sending it to the
  /// platform side. It should match the codec passed to the constructor of [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#PlatformViewFactory-io.flutter.plugin.common.MessageCodec-).
  ///
  /// This is typically one of: [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec].
  ///
  /// This must not be null if [creationParams] is not null.
  final MessageCodec<dynamic>? creationParamsCodec;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  final Clip clipBehavior;

  /// Prefer using Virtual display mode
  final bool useVirtualDisplay;

  @override
  State<SimpleAndroidView> createState() => _SimpleAndroidViewState();
}

class _SimpleAndroidViewState extends State<SimpleAndroidView> {
  int? _id;
  late AndroidViewController _controller;
  TextDirection? _layoutDirection;
  bool _initialized = false;
  bool _platformViewCreated = false;
  FocusNode? _focusNode;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
  <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    final Widget androidView = Focus(
      focusNode: _focusNode,
      onFocusChange: _onFocusChange,
      child: _SimpleAndroidPlatformView(
        controller: _controller,
        hitTestBehavior: widget.hitTestBehavior,
        gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
        clipBehavior: widget.clipBehavior,
      ),
    );
    return CustomPaint(
      painter: _platformViewCreated && _controller.textureId == null ? ClearBackgroundPainter() : null,
      child: androidView,
    );
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewAndroidView();
    _focusNode = FocusNode(debugLabel: 'SimpleAndroidView(id: $_id)');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    _initializeOnce();
    if (didChangeLayoutDirection) {
      // The native view will update asynchronously, in the meantime we don't want
      // to block the framework. (so this is intentionally not awaiting).
      _controller.setLayoutDirection(_layoutDirection!);
    }
  }

  @override
  void didUpdateWidget(SimpleAndroidView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (widget.viewType != oldWidget.viewType) {
      _controller.disposePostFrame();
      _createNewAndroidView();
      return;
    }

    if (didChangeLayoutDirection) {
      _controller.setLayoutDirection(_layoutDirection!);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(widget.layoutDirection != null || debugCheckHasDirectionality(context));
    return widget.layoutDirection ?? Directionality.of(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode?.dispose();
    _focusNode = null;
    super.dispose();
  }

  void _createNewAndroidView() {
    _id = SimplePlatformViewsService.instance.getNextPlatformViewId();
    _controller = SimplePlatformViewsService.initAndroidView(
      id: _id!,
      viewType: widget.viewType,
      layoutDirection: _layoutDirection!,
      creationParams: widget.creationParams,
      creationParamsCodec: widget.creationParamsCodec,
      onFocus: () {
        _focusNode!.requestFocus();
      },
      useVirtualDisplay: widget.useVirtualDisplay,
    );
    _controller.addOnPlatformViewCreatedListener((int id) {
      setState(() {
        _platformViewCreated = true;
      });
      widget.onPlatformViewCreated?.call(id);
    });
  }

  void _onFocusChange(bool isFocused) {
    if (!_controller.isCreated) {
      return;
    }
    if (!isFocused) {
      _controller.clearFocus().catchError((dynamic e) {
        if (e is MissingPluginException) {
          // We land the framework part of Android platform views keyboard
          // support before the engine part. There will be a commit range where
          // clearFocus isn't implemented in the engine. When that happens we
          // just swallow the error here. Once the engine part is rolled to the
          // framework I'll remove this.
          // TODO(amirh): remove this once the engine's clearFocus is rolled.
          return;
        }
      });
      return;
    }
    /*
    SystemChannels.textInput.invokeMethod<void>(
      'TextInput.setPlatformViewClient',
      <String, dynamic>{'platformViewId': _id},
    ).catchError((dynamic e) {
      if (e is MissingPluginException) {
        // We land the framework part of Android platform views keyboard
        // support before the engine part. There will be a commit range where
        // setPlatformViewClient isn't implemented in the engine. When that
        // happens we just swallow the error here. Once the engine part is
        // rolled to the framework I'll remove this.
        // TODO(amirh): remove this once the engine's clearFocus is rolled.
        return;
      }
    });
    */
  }
}

class _SimpleAndroidPlatformView extends LeafRenderObjectWidget {
  const _SimpleAndroidPlatformView({
    required this.controller,
    required this.hitTestBehavior,
    required this.gestureRecognizers,
    this.clipBehavior = Clip.hardEdge,
  });

  final AndroidViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderAndroidView(
        viewController: controller,
        hitTestBehavior: hitTestBehavior,
        gestureRecognizers: gestureRecognizers,
        clipBehavior: clipBehavior,
      );

  @override
  void updateRenderObject(BuildContext context, RenderAndroidView renderObject) {
    renderObject.controller = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
    renderObject.clipBehavior = clipBehavior;
  }
}

extension on PlatformViewController {
  /// Disposes the controller in a post-frame callback, to allow other widgets to
  /// remove their listeners before the controller is disposed.
  void disposePostFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      dispose();
    });
  }
}

/// Controls an Android view created by Opaque hybrid composition mode.
class SimpleAndroidViewController implements AndroidViewController {
  SimpleAndroidViewController({
    required this.viewId,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    this.useVirtualDisplay = false,
  })  : assert(creationParams == null || creationParamsCodec != null),
        _viewType = viewType,
        _layoutDirection = layoutDirection,
        _creationParams = creationParams == null ? null : _CreationParams(creationParams, creationParamsCodec!);

  /// The unique identifier of the Android view controlled by this controller.
  @override
  final int viewId;

  final String _viewType;

  /// The current offset of the platform view.
  Offset _offset = Offset.zero;

  // Helps convert PointerEvents to AndroidMotionEvents.
  final _AndroidMotionEventConverter _motionEventConverter =
  _AndroidMotionEventConverter();

  TextDirection _layoutDirection;

  _AndroidViewState _state = _AndroidViewState.waitingForSize;

  final _CreationParams? _creationParams;

  final List<PlatformViewCreatedCallback> _platformViewCreatedCallbacks =
  <PlatformViewCreatedCallback>[];

  final bool useVirtualDisplay;

  static int _getAndroidDirection(TextDirection direction) {
    switch (direction) {
      case TextDirection.ltr:
        return AndroidViewController.kAndroidLayoutDirectionLtr;
      case TextDirection.rtl:
        return AndroidViewController.kAndroidLayoutDirectionRtl;
    }
  }

  /// Creates a masked Android MotionEvent action value for an indexed pointer.
  static int pointerAction(int pointerId, int action) {
    return ((pointerId << 8) & 0xff00) | (action & 0xff);
  }

  Future<void> _sendDisposeMessage() {
    return SimpleSystemChannels
        .platformViewsChannel.invokeMethod<void>('dispose', <String, dynamic>{
      'id': viewId,
    });
  }

  bool get _createRequiresSize => true;

  Future<void> _sendCreateMessage({required Size size, Offset? position}) async {
    assert(!size.isEmpty, 'trying to create $SimpleAndroidViewController without setting a valid size.');
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': _viewType,
      'direction': _getAndroidDirection(_layoutDirection),
      'width': size.width,
      'height': size.height,
      if (position != null) 'left': position.dx,
      if (position != null) 'top': position.dy,
      if (useVirtualDisplay) 'useVirtualDisplay': true,
    };
    if (_creationParams != null) {
      final ByteData paramsByteData = _creationParams!.codec.encodeMessage(_creationParams!.data)!;
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    final textureId = await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>('create', args);
    if (textureId is int && textureId >= 0) {
      _textureId = textureId;
    }
  }

  Future<Size> _sendResizeMessage(Size size) async {
    assert(_state != _AndroidViewState.waitingForSize, 'Android view must have an initial size. View id: $viewId');
    assert(!size.isEmpty);

    final Map<Object?, Object?>? meta = await SimpleSystemChannels.platformViewsChannel.invokeMapMethod<Object?, Object?>(
      'resize',
      <String, dynamic>{
        'id': viewId,
        'width': size.width,
        'height': size.height,
      },
    );
    assert(meta != null);
    assert(meta!.containsKey('width'));
    assert(meta!.containsKey('height'));
    return Size(meta!['width']! as double, meta['height']! as double);
  }

  @override
  bool get awaitingCreation => _state == _AndroidViewState.waitingForSize;

  @override
  Future<void> create({Size? size, Offset? position}) async {
    assert(_state != _AndroidViewState.disposed, 'trying to create a disposed Android view');
    assert(_state == _AndroidViewState.waitingForSize, 'Android view is already sized. View id: $viewId');

    if (_createRequiresSize && size == null) {
      // Wait for a setSize call.
      return;
    }

    _state = _AndroidViewState.creating;
    await _sendCreateMessage(size: size ?? Size.zero, position: position);
    _state = _AndroidViewState.created;

    for (final PlatformViewCreatedCallback callback in _platformViewCreatedCallbacks) {
      callback(viewId);
    }
  }

  @override
  Future<Size> setSize(Size size) async {
    assert(_state != _AndroidViewState.disposed, 'Android view is disposed. View id: $viewId');
    if (_state == _AndroidViewState.waitingForSize) {
      // Either `create` hasn't been called, or it couldn't run due to missing
      // size information, so create the view now.
      await create(size: size);
      return size;
    } else {
      return _sendResizeMessage(size);
    }
  }

  @override
  Future<void> setOffset(Offset offset) async {
    if (offset == _offset) {
      return;
    }

    // Don't set the offset unless the Android view has been created.
    // The implementation of this method channel throws if the Android view for this viewId
    // isn't addressable.
    if (_state != _AndroidViewState.created) {
      return;
    }

    _offset = offset;

    await SimpleSystemChannels.platformViewsChannel.invokeMethod<void>(
      'offset',
      <String, dynamic>{
        'id': viewId,
        'top': offset.dy,
        'left': offset.dx,
      },
    );
  }

  int? _textureId;

  @override
  int? get textureId => _textureId;

  @override
  bool get requiresViewComposition => false;

  @override
  Future<void> sendMotionEvent(AndroidMotionEvent event) async {
    await SimpleSystemChannels.platformViewsChannel.invokeMethod<dynamic>(
      'touch',
      event._asList(viewId),
    );
  }

  @override
  PointTransformer get pointTransformer => _motionEventConverter.pointTransformer;

  @override
  set pointTransformer(PointTransformer transformer) {
    _motionEventConverter.pointTransformer = transformer;
  }

  /// Whether the platform view has already been created.
  @override
  bool get isCreated => _state == _AndroidViewState.created;

  /// Adds a callback that will get invoke after the platform view has been
  /// created.
  @override
  void addOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.add(listener);
  }

  /// Removes a callback added with [addOnPlatformViewCreatedListener].
  @override
  void removeOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.remove(listener);
  }

  /// The created callbacks that are invoked after the platform view has been
  /// created.
  @override
  @visibleForTesting
  List<PlatformViewCreatedCallback> get createdCallbacks => _platformViewCreatedCallbacks;

  /// Sets the layout direction for the Android view.
  @override
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(
    _state != _AndroidViewState.disposed,
    'trying to set a layout direction for a disposed Android view. View id: $viewId',
    );

    if (layoutDirection == _layoutDirection) {
      return;
    }

    _layoutDirection = layoutDirection;

    // If the view was not yet created we just update _layoutDirection and return, as the new
    // direction will be used in _create.
    if (_state == _AndroidViewState.waitingForSize) {
      return;
    }

    await SimpleSystemChannels.platformViewsChannel
        .invokeMethod<void>('setDirection', <String, dynamic>{
      'id': viewId,
      'direction': _getAndroidDirection(layoutDirection),
    });
  }

  /// Converts the [PointerEvent] and sends an Android [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent)
  /// to the view.
  ///
  /// This method can only be used if a [PointTransformer] is provided to
  /// [AndroidViewController.pointTransformer]. Otherwise, an [AssertionError]
  /// is thrown. See [AndroidViewController.sendMotionEvent] for sending a
  /// `MotionEvent` without a [PointTransformer].
  ///
  /// The Android MotionEvent object is created with [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int)).
  /// See documentation of [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int))
  /// for description of the parameters.
  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    if (event is PointerHoverEvent) {
      return;
    }

    if (event is PointerDownEvent) {
      _motionEventConverter.handlePointerDownEvent(event);
    }

    _motionEventConverter.updatePointerPositions(event);

    final AndroidMotionEvent? androidEvent =
    _motionEventConverter.toAndroidMotionEvent(event);

    if (event is PointerUpEvent) {
      _motionEventConverter.handlePointerUpEvent(event);
    } else if (event is PointerCancelEvent) {
      _motionEventConverter.handlePointerCancelEvent(event);
    }

    if (androidEvent != null) {
      await sendMotionEvent(androidEvent);
    }
  }

  /// Clears the focus from the Android View if it is focused.
  @override
  Future<void> clearFocus() {
    if (_state != _AndroidViewState.created) {
      return Future<void>.value();
    }
    return SimpleSystemChannels.platformViewsChannel.invokeMethod<void>('clearFocus', viewId);
  }

  /// Disposes the Android view.
  ///
  /// The [AndroidViewController] object is unusable after calling this.
  /// The identifier of the platform view cannot be reused after the view is
  /// disposed.
  @override
  Future<void> dispose() async {
    final _AndroidViewState state = _state;
    _state = _AndroidViewState.disposed;
    _platformViewCreatedCallbacks.clear();
    SimplePlatformViewsService.instance.focusCallbacks.remove(viewId);
    if (state == _AndroidViewState.creating || state == _AndroidViewState.created) {
      await _sendDisposeMessage();
    }
  }
}

extension on AndroidMotionEvent {
  List<dynamic> _asList(int viewId) {
    return <dynamic>[
      viewId,
      downTime,
      eventTime,
      action,
      pointerCount,
      pointerProperties.map<List<int>>((AndroidPointerProperties p) => p._asList()).toList(),
      pointerCoords.map<List<double>>((AndroidPointerCoords p) => p._asList()).toList(),
      metaState,
      buttonState,
      xPrecision,
      yPrecision,
      deviceId,
      edgeFlags,
      source,
      flags,
      motionEventId,
    ];
  }
}

extension on AndroidPointerProperties {
  List<int> _asList() => <int>[id, toolType];
}

extension on AndroidPointerCoords {
  List<double> _asList() {
    return <double>[
      orientation,
      pressure,
      size,
      toolMajor,
      toolMinor,
      touchMajor,
      touchMinor,
      x,
      y,
    ];
  }
}

enum _AndroidViewState {
  waitingForSize,
  creating,
  created,
  disposed,
}

class _CreationParams {
  const _CreationParams(this.data, this.codec);
  final dynamic data;
  final MessageCodec<dynamic> codec;
}

// Helper for converting PointerEvents into AndroidMotionEvents.
class _AndroidMotionEventConverter {
  _AndroidMotionEventConverter();

  final Map<int, AndroidPointerCoords> pointerPositions =
  <int, AndroidPointerCoords>{};
  final Map<int, AndroidPointerProperties> pointerProperties =
  <int, AndroidPointerProperties>{};
  final Set<int> usedAndroidPointerIds = <int>{};

  late PointTransformer pointTransformer;

  int? downTimeMillis;

  void handlePointerDownEvent(PointerDownEvent event) {
    if (pointerProperties.isEmpty) {
      downTimeMillis = event.timeStamp.inMilliseconds;
    }
    int androidPointerId = 0;
    while (usedAndroidPointerIds.contains(androidPointerId)) {
      androidPointerId++;
    }
    usedAndroidPointerIds.add(androidPointerId);
    pointerProperties[event.pointer] = propertiesFor(event, androidPointerId);
  }

  void updatePointerPositions(PointerEvent event) {
    final Offset position = pointTransformer(event.position);
    pointerPositions[event.pointer] = AndroidPointerCoords(
      orientation: event.orientation,
      pressure: event.pressure,
      size: event.size,
      toolMajor: event.radiusMajor,
      toolMinor: event.radiusMinor,
      touchMajor: event.radiusMajor,
      touchMinor: event.radiusMinor,
      x: position.dx,
      y: position.dy,
    );
  }

  void _remove(int pointer) {
    pointerPositions.remove(pointer);
    usedAndroidPointerIds.remove(pointerProperties[pointer]!.id);
    pointerProperties.remove(pointer);
    if (pointerProperties.isEmpty) {
      downTimeMillis = null;
    }
  }

  void handlePointerUpEvent(PointerUpEvent event) {
    _remove(event.pointer);
  }

  void handlePointerCancelEvent(PointerCancelEvent event) {
    // The pointer cancel event is handled like pointer up. Normally,
    // the difference is that pointer cancel doesn't perform any action,
    // but in this case neither up or cancel perform any action.
    _remove(event.pointer);
  }

  AndroidMotionEvent? toAndroidMotionEvent(PointerEvent event) {
    final List<int> pointers = pointerPositions.keys.toList();
    final int pointerIdx = pointers.indexOf(event.pointer);
    final int numPointers = pointers.length;

    // This value must match the value in engine's FlutterView.java.
    // This flag indicates whether the original Android pointer events were batched together.
    const int kPointerDataFlagBatched = 1;

    // Android MotionEvent objects can batch information on multiple pointers.
    // Flutter breaks these such batched events into multiple PointerEvent objects.
    // When there are multiple active pointers we accumulate the information for all pointers
    // as we get PointerEvents, and only send it to the embedded Android view when
    // we see the last pointer. This way we achieve the same batching as Android.
    if (event.platformData == kPointerDataFlagBatched ||
        (isSinglePointerAction(event) && pointerIdx < numPointers - 1)) {
      return null;
    }

    final int action;
    if (event is PointerDownEvent) {
      action = numPointers == 1
          ? AndroidViewController.kActionDown
          : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerDown);
    } else if (event is PointerUpEvent) {
      action = numPointers == 1
          ? AndroidViewController.kActionUp
          : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerUp);
    } else if (event is PointerMoveEvent) {
      action = AndroidViewController.kActionMove;
    } else if (event is PointerCancelEvent) {
      action = AndroidViewController.kActionCancel;
    } else {
      return null;
    }

    return AndroidMotionEvent(
      downTime: downTimeMillis!,
      eventTime: event.timeStamp.inMilliseconds,
      action: action,
      pointerCount: pointerPositions.length,
      pointerProperties: pointers
          .map<AndroidPointerProperties>((int i) => pointerProperties[i]!)
          .toList(),
      pointerCoords: pointers
          .map<AndroidPointerCoords>((int i) => pointerPositions[i]!)
          .toList(),
      metaState: 0,
      buttonState: 0,
      xPrecision: 1.0,
      yPrecision: 1.0,
      deviceId: 0,
      edgeFlags: 0,
      source: 0,
      flags: 0,
      motionEventId: event.embedderId,
    );
  }

  AndroidPointerProperties propertiesFor(PointerEvent event, int pointerId) {
    int toolType = AndroidPointerProperties.kToolTypeUnknown;
    switch (event.kind) {
      case PointerDeviceKind.touch:
      case PointerDeviceKind.trackpad:
        toolType = AndroidPointerProperties.kToolTypeFinger;
        break;
      case PointerDeviceKind.mouse:
        toolType = AndroidPointerProperties.kToolTypeMouse;
        break;
      case PointerDeviceKind.stylus:
        toolType = AndroidPointerProperties.kToolTypeStylus;
        break;
      case PointerDeviceKind.invertedStylus:
        toolType = AndroidPointerProperties.kToolTypeEraser;
        break;
      case PointerDeviceKind.unknown:
        toolType = AndroidPointerProperties.kToolTypeUnknown;
        break;
    }
    return AndroidPointerProperties(id: pointerId, toolType: toolType);
  }

  bool isSinglePointerAction(PointerEvent event) =>
      event is! PointerDownEvent && event is! PointerUpEvent;
}