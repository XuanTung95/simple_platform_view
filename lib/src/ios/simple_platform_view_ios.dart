
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_platform_view/src/common/clear_background_painter.dart';
import 'package:simple_platform_view/src/common/simple_platform_view_service.dart';
import 'package:simple_platform_view/src/common/simple_system_channels.dart';

// TODO(amirh): describe the embedding mechanism.
// TODO(ychris): remove the documentation for conic path not supported once https://github.com/flutter/flutter/issues/35062 is resolved.
/// Embeds an iOS view in the Widget hierarchy.
///
/// Embedding iOS views is an expensive operation and should be avoided when a Flutter
/// equivalent is possible.
///
/// {@macro flutter.widgets.AndroidView.layout}
///
/// {@macro flutter.widgets.AndroidView.gestures}
///
/// {@macro flutter.widgets.AndroidView.lifetime}
///
/// Construction of UIViews is done asynchronously, before the UIView is ready this widget paints
/// nothing while maintaining the same layout constraints.
///
/// Clipping operations on a UiKitView can result slow performance.
/// If a conic path clipping is applied to a UIKitView,
/// a quad path is used to approximate the clip due to limitation of Quartz.
class SimpleUiKitView extends StatefulWidget {
  /// Creates a widget that embeds an iOS view.
  ///
  /// {@macro flutter.widgets.AndroidView.constructorArgs}
  const SimpleUiKitView({
    super.key,
    required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.creationParams,
    this.creationParamsCodec,
    this.gestureRecognizers,
  }) : assert(creationParams == null || creationParamsCodec != null);

  // TODO(amirh): reference the iOS API doc once available.
  /// The unique identifier for iOS view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  /// {@macro flutter.widgets.AndroidView.onPlatformViewCreated}
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  /// {@macro flutter.widgets.AndroidView.hitTestBehavior}
  final PlatformViewHitTestBehavior hitTestBehavior;

  /// {@macro flutter.widgets.AndroidView.layoutDirection}
  final TextDirection? layoutDirection;

  /// Passed as the `arguments` argument of [-\[FlutterPlatformViewFactory createWithFrame:viewIdentifier:arguments:\]](/objcdoc/Protocols/FlutterPlatformViewFactory.html#/c:objc(pl)FlutterPlatformViewFactory(im)createWithFrame:viewIdentifier:arguments:)
  ///
  /// This can be used by plugins to pass constructor parameters to the embedded iOS view.
  final dynamic creationParams;

  /// The codec used to encode `creationParams` before sending it to the
  /// platform side. It should match the codec returned by [-\[FlutterPlatformViewFactory createArgsCodec:\]](/objcdoc/Protocols/FlutterPlatformViewFactory.html#/c:objc(pl)FlutterPlatformViewFactory(im)createArgsCodec)
  ///
  /// This is typically one of: [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec].
  ///
  /// This must not be null if [creationParams] is not null.
  final MessageCodec<dynamic>? creationParamsCodec;

  /// Which gestures should be forwarded to the UIKit view.
  ///
  /// {@macro flutter.widgets.AndroidView.gestureRecognizers.descHead}
  ///
  /// For example, with the following setup vertical drags will not be dispatched to the UIKit
  /// view as the vertical drag gesture is claimed by the parent [GestureDetector].
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: const UiKitView(
  ///     viewType: 'webview',
  ///   ),
  /// )
  /// ```
  ///
  /// To get the [SimpleUiKitView] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: UiKitView(
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
  /// {@macro flutter.widgets.AndroidView.gestureRecognizers.descFoot}
  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<SimpleUiKitView> createState() => _SimpleUiKitViewState();
}

class _SimpleUiKitViewState extends State<SimpleUiKitView> {
  late SimpleUiKitViewController _controller;
  TextDirection? _layoutDirection;
  bool _initialized = false;
  bool _platformViewCreated = false;
  @visibleForTesting
  FocusNode? focusNode;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
  <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    final SimpleUiKitViewController controller = _controller;
    Widget uiKitView = Focus(
      focusNode: focusNode,
      onFocusChange: (bool isFocused) => _onFocusChange(isFocused, controller),
      child: _SimpleUiKitPlatformView(
        controller: _controller,
        hitTestBehavior: widget.hitTestBehavior,
        gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
      ),
    );
    return CustomPaint(
      painter: _platformViewCreated ? ClearBackgroundPainter() : null,
      child: uiKitView,
    );
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewUiKitView();
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
  void didUpdateWidget(SimpleUiKitView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (widget.viewType != oldWidget.viewType) {
      _controller.dispose();
      _createNewUiKitView();
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
    focusNode?.dispose();
    focusNode = null;
    super.dispose();
  }

  Future<void> _createNewUiKitView() async {
    final int id = SimplePlatformViewsService.instance.getNextPlatformViewId();
    _controller = SimplePlatformViewsService.initUiKitView(
        id: id,
        viewType: widget.viewType,
        layoutDirection: _layoutDirection!,
        creationParams: widget.creationParams,
        creationParamsCodec: widget.creationParamsCodec,
        onFocus: () {
          focusNode?.requestFocus();
        }
    );
    _controller.addOnPlatformViewCreatedListener((int id) {
      if (!mounted) {
        return;
      }
      setState(() {
        _platformViewCreated = true;
      });
      widget.onPlatformViewCreated?.call(id);
    });
    focusNode = FocusNode(debugLabel: 'UiKitView(id: $id)');
  }

  void _onFocusChange(bool isFocused, UiKitViewController controller) {
    if (!isFocused) {
      // Unlike Android, we do not need to send "clearFocus" channel message
      // to the engine, because focusing on another view will automatically
      // cancel the focus on the previously focused platform view.
      return;
    }
    /*
    SystemChannels.textInput.invokeMethod<void>(
      'TextInput.setPlatformViewClient',
      <String, dynamic>{'platformViewId': controller.id},
    );
    */
  }
}

class _SimpleUiKitPlatformView extends LeafRenderObjectWidget {
  const _SimpleUiKitPlatformView({
    required this.controller,
    required this.hitTestBehavior,
    required this.gestureRecognizers,
  });

  final SimpleUiKitViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SimpleRenderUiKitView(
      viewController: controller,
      hitTestBehavior: hitTestBehavior,
      gestureRecognizers: gestureRecognizers,
    );
  }

  @override
  void updateRenderObject(BuildContext context, SimpleRenderUiKitView renderObject) {
    renderObject.viewController = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
  }
}

/// A render object for an iOS UIKit UIView.
///
/// [SimpleRenderUiKitView] is responsible for sizing and displaying an iOS
/// [UIView](https://developer.apple.com/documentation/uikit/uiview).
///
/// UIViews are added as sub views of the FlutterView and are composited by Quartz.
///
/// {@macro flutter.rendering.RenderAndroidView.layout}
///
/// {@macro flutter.rendering.RenderAndroidView.gestures}
///
/// See also:
///
///  * [UiKitView] which is a widget that is used to show a UIView.
///  * [PlatformViewsService] which is a service for controlling platform views.
class SimpleRenderUiKitView extends RenderBox {
  /// Creates a render object for an iOS UIView.
  ///
  /// The `viewId`, `hitTestBehavior`, and `gestureRecognizers` parameters must not be null.
  SimpleRenderUiKitView({
    required SimpleUiKitViewController viewController,
    required this.hitTestBehavior,
    required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  }) : _viewController = viewController {
    updateGestureRecognizers(gestureRecognizers);
    _setOffset();
  }

  bool _isDisposed = false;

  /// The unique identifier of the UIView controlled by this controller.
  ///
  /// Typically generated by [PlatformViewsRegistry.getNextPlatformViewId], the UIView
  /// must have been created by calling [PlatformViewsService.initUiKitView].
  SimpleUiKitViewController get viewController => _viewController;
  SimpleUiKitViewController _viewController;
  set viewController(SimpleUiKitViewController value) {
    if (_viewController == value) {
      return;
    }
    final bool needsSemanticsUpdate = _viewController.id != value.id;
    _viewController = value;
    markNeedsPaint();
    if (needsSemanticsUpdate) {
      markNeedsSemanticsUpdate();
    }
  }

  /// How to behave during hit testing.
  // The implicit setter is enough here as changing this value will just affect
  // any newly arriving events there's nothing we need to invalidate.
  PlatformViewHitTestBehavior hitTestBehavior;

  /// {@macro flutter.rendering.PlatformViewRenderBox.updateGestureRecognizers}
  void updateGestureRecognizers(Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    assert(
    _factoriesTypeSet(gestureRecognizers).length == gestureRecognizers.length,
    'There were multiple gesture recognizer factories for the same type, there must only be a single '
        'gesture recognizer factory for each gesture recognizer type.',
    );
    if (_factoryTypesSetEquals(gestureRecognizers, _gestureRecognizer?.gestureRecognizerFactories)) {
      return;
    }
    _gestureRecognizer?.dispose();
    _gestureRecognizer = _UiKitViewGestureRecognizer(viewController, gestureRecognizers);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => false;

  @override
  bool get isRepaintBoundary => true;

  _UiKitViewGestureRecognizer? _gestureRecognizer;

  PointerEvent? _lastPointerDownEvent;

  _PlatformViewState _state = _PlatformViewState.uninitialized;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performResize() {
    super.performResize();
    _sizePlatformView();
  }

  Future<void> _sizePlatformView() async {
    if (_state == _PlatformViewState.resizing || size.isEmpty) {
      return;
    }
    _state = _PlatformViewState.resizing;
    markNeedsPaint();

    Size targetSize;
    do {
      targetSize = size;
      await _viewController.setSize(targetSize);
      if (_isDisposed) {
        return;
      }
      // We've resized the platform view to targetSize, but it is possible that
      // while we were resizing the render object's size was changed again.
      // In that case we will resize the platform view again.
    } while (size != targetSize);

    _state = _PlatformViewState.ready;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // noop
  }

  @override
  bool hitTest(BoxHitTestResult result, { Offset? position }) {
    if (hitTestBehavior == PlatformViewHitTestBehavior.transparent || !size.contains(position!)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) => hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is! PointerDownEvent) {
      return;
    }
    _gestureRecognizer!.addPointer(event);
    _lastPointerDownEvent = event.original ?? event;
  }

  // This is registered as a global PointerRoute while the render object is attached.
  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }
    if (!(Offset.zero & size).contains(globalToLocal(event.position))) {
      return;
    }
    if ((event.original ?? event) != _lastPointerDownEvent) {
      // The pointer event is in the bounds of this render box, but we didn't get it in handleEvent.
      // This means that the pointer event was absorbed by a different render object.
      // Since on the platform side the FlutterTouchIntercepting view is seeing all events that are
      // within its bounds we need to tell it to reject the current touch sequence.
      _viewController.rejectGesture();
    }
    _lastPointerDownEvent = null;
  }

  @override
  void describeSemanticsConfiguration (SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.platformViewId = _viewController.id;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointerEvent);
  }

  @override
  void detach() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleGlobalPointerEvent);
    _gestureRecognizer!.reset();
    super.detach();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Sets the offset of the underlying platform view on the platform side.
  //
  // This allows the Android native view to draw the a11y highlights in the same
  // location on the screen as the platform view widget in the Flutter framework.
  //
  // It also allows platform code to obtain the correct position of the Android
  // native view on the screen.
  void _setOffset() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!_isDisposed) {
        if (attached) {
          await _viewController.setOffset(localToGlobal(Offset.zero));
        }
        // Schedule a new post frame callback.
        _setOffset();
      }
    });
  }
}

Set<Type> _factoriesTypeSet<T>(Set<Factory<T>> factories) {
  return factories.map<Type>((Factory<T> factory) => factory.type).toSet();
}

bool _factoryTypesSetEquals<T>(Set<Factory<T>>? a, Set<Factory<T>>? b) {
  if (a == b) {
    return true;
  }
  if (a == null ||  b == null) {
    return false;
  }
  return setEquals(_factoriesTypeSet(a), _factoriesTypeSet(b));
}

// This recognizer constructs gesture recognizers from a set of gesture recognizer factories
// it was give, adds all of them to a gesture arena team with the _UiKitViewGestureRecognizer
// as the team captain.
// When the team wins a gesture the recognizer notifies the engine that it should release
// the touch sequence to the embedded UIView.
class _UiKitViewGestureRecognizer extends OneSequenceGestureRecognizer {
  _UiKitViewGestureRecognizer(
      this.controller,
      this.gestureRecognizerFactories
      ) {
    team = GestureArenaTeam()
      ..captain = this;
    _gestureRecognizers = gestureRecognizerFactories.map(
          (Factory<OneSequenceGestureRecognizer> recognizerFactory) {
        final OneSequenceGestureRecognizer gestureRecognizer = recognizerFactory.constructor();
        gestureRecognizer.team = team;
        // The below gesture recognizers requires at least one non-empty callback to
        // compete in the gesture arena.
        // https://github.com/flutter/flutter/issues/35394#issuecomment-562285087
        if (gestureRecognizer is LongPressGestureRecognizer) {
          gestureRecognizer.onLongPress ??= (){};
        } else if (gestureRecognizer is DragGestureRecognizer) {
          gestureRecognizer.onDown ??= (_){};
        } else if (gestureRecognizer is TapGestureRecognizer) {
          gestureRecognizer.onTapDown ??= (_){};
        }
        return gestureRecognizer;
      },
    ).toSet();
  }

  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories;
  late Set<OneSequenceGestureRecognizer> _gestureRecognizers;

  final UiKitViewController controller;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    for (final OneSequenceGestureRecognizer recognizer in _gestureRecognizers) {
      recognizer.addPointer(event);
    }
  }

  @override
  String get debugDescription => 'Simple UIKit view';

  @override
  void didStopTrackingLastPointer(int pointer) { }

  @override
  void handleEvent(PointerEvent event) {
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    controller.acceptGesture();
  }

  @override
  void rejectGesture(int pointer) {
    controller.rejectGesture();
  }

  void reset() {
    resolve(GestureDisposition.rejected);
  }
}

class SimpleUiKitViewController implements UiKitViewController {
  /// The unique identifier of the iOS view controlled by this controller.
  ///
  /// This identifier is typically generated by
  /// [PlatformViewsRegistry.getNextPlatformViewId].
  @override
  final int id;

  bool _debugDisposed = false;

  TextDirection _layoutDirection;

  final String viewType;
  final dynamic _creationParams;
  final MessageCodec<dynamic>? _creationParamsCodec;

  /// The current offset of the platform view.
  Offset _offset = Offset.zero;

  _UiKitViewState _state = _UiKitViewState.waitingForSize;

  bool get awaitingCreation => _state == _UiKitViewState.waitingForSize;

  bool get isCreated => _state == _UiKitViewState.created;

  final List<PlatformViewCreatedCallback> _platformViewCreatedCallbacks =
  <PlatformViewCreatedCallback>[];

  List<PlatformViewCreatedCallback> get createdCallbacks => _platformViewCreatedCallbacks;

  SimpleUiKitViewController({
    required this.id,
    required this.viewType,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    required TextDirection layoutDirection,
  }) : _creationParams = creationParams, _creationParamsCodec = creationParamsCodec, _layoutDirection = layoutDirection;

  Future<void> create({required Size size, Offset? position}) async {
    assert(_state != _UiKitViewState.disposed, 'trying to create a disposed Android view');
    assert(_state == _UiKitViewState.waitingForSize, 'Android view is already sized. View id: $id');

    if (size.isEmpty) {
      // Wait for a setSize call.
      return;
    }

    _state = _UiKitViewState.creating;
    await _sendCreateMessage(size: size, position: position);
    _state = _UiKitViewState.created;

    for (final PlatformViewCreatedCallback callback in _platformViewCreatedCallbacks) {
      callback(id);
    }
  }

  Future<void> _sendCreateMessage({required Size size, Offset? position}) async {
    assert(!size.isEmpty, 'trying to create $SimpleUiKitViewController without setting a valid size.');
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
      'viewType': viewType,
      'width': size.width,
      'height': size.height,
      if (position != null) 'left': position.dx,
      if (position != null) 'top': position.dy,
    };
    if (_creationParams != null) {
      final ByteData paramsByteData = _creationParamsCodec!.encodeMessage(_creationParams)!;
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    await SimpleSystemChannels.platformViewsChannel.invokeMethod<void>('create', args);
  }

  /// Adds a callback that will get invoke after the platform view has been
  /// created.
  void addOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(_state != _UiKitViewState.disposed);
    _platformViewCreatedCallbacks.add(listener);
  }

  /// Removes a callback added with [addOnPlatformViewCreatedListener].
  void removeOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(_state != _UiKitViewState.disposed);
    _platformViewCreatedCallbacks.remove(listener);
  }

  @override
  Future<void> acceptGesture() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
    };
    return SimpleSystemChannels.platformViewsChannel.invokeMethod('acceptGesture', args);
  }

  @override
  Future<void> dispose() async {
    final _UiKitViewState state = _state;
    _state = _UiKitViewState.disposed;
    _platformViewCreatedCallbacks.clear();
    _debugDisposed = true;
    SimplePlatformViewsService.instance.focusCallbacks.remove(id);
    if (state == _UiKitViewState.creating || state == _UiKitViewState.created) {
      await _sendDisposeMessage();
    }
  }

  Future<void> _sendDisposeMessage() {
    return SimpleSystemChannels.platformViewsChannel.invokeMethod<void>('dispose', <String, dynamic>{
      'id': id,
    });
  }

  @override
  Future<void> rejectGesture() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
    };
    return SimpleSystemChannels.platformViewsChannel.invokeMethod('rejectGesture', args);
  }

  @override
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(!_debugDisposed, 'trying to set a layout direction for a disposed iOS UIView. View id: $id');

    if (layoutDirection == _layoutDirection) {
      return;
    }

    _layoutDirection = layoutDirection;
  }

  Future<void> setOffset(Offset offset) async {
    if (offset == _offset) {
      return;
    }

    // Don't set the offset unless the Android view has been created.
    // The implementation of this method channel throws if the Android view for this viewId
    // isn't addressable.
    if (_state != _UiKitViewState.created) {
      return;
    }

    _offset = offset;

    await SimpleSystemChannels.platformViewsChannel.invokeMethod<void>(
      'offset',
      <String, dynamic>{
        'id': id,
        'top': offset.dy,
        'left': offset.dx,
      },
    );
  }

  Future<Size> setSize(Size size, {Offset? position}) async {
    assert(_state != _UiKitViewState.disposed, 'Android view is disposed. View id: $id');
    if (_state == _UiKitViewState.waitingForSize) {
      // Either `create` hasn't been called, or it couldn't run due to missing
      // size information, so create the view now.
      await create(size: size, position: position);
      return size;
    } else {
      return _sendResizeMessage(size);
    }
  }

  Future<Size> _sendResizeMessage(Size size) async {
    assert(!size.isEmpty);

    final Map<Object?, Object?>? meta = await SimpleSystemChannels.platformViewsChannel.invokeMapMethod<Object?, Object?>(
      'resize',
      <String, dynamic>{
        'id': id,
        'width': size.width,
        'height': size.height,
      },
    );
    assert(meta != null);
    assert(meta!.containsKey('width'));
    assert(meta!.containsKey('height'));
    return Size(meta!['width']! as double, meta['height']! as double);
  }
}

enum _PlatformViewState {
  uninitialized,
  resizing,
  ready,
}

enum _UiKitViewState {
  waitingForSize,
  creating,
  created,
  disposed,
}