package com.tungpx.platform.view.simple_platform_view;

import static android.view.MotionEvent.PointerCoords;
import static android.view.MotionEvent.PointerProperties;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.content.MutableContextWrapper;
import android.os.Build;
import android.util.SparseArray;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import androidx.annotation.VisibleForTesting;
import io.flutter.Log;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.MotionEventTracker;
import io.flutter.embedding.engine.mutatorsstack.*;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.plugin.platform.PlatformViewsAccessibilityDelegate;
import io.flutter.view.AccessibilityBridge;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

/**
 * Manages platform views.
 *
 * <p>Each {@link io.flutter.embedding.engine.FlutterEngine} or {@link
 * io.flutter.app.FlutterPluginRegistry} has a single platform views controller. A platform views
 * controller can be attached to at most one Flutter view.
 */
public class SimplePlatformViewsController implements PlatformViewsAccessibilityDelegate {
  private static final String TAG = "SimplePlatformViewsController";

  private AndroidTouchProcessor androidTouchProcessor;

  // The context of the Activity or Fragment hosting the render target for the Flutter engine.
  private Context context;

  // The View currently rendering the Flutter UI associated with these platform views.
  private FlutterView flutterView;

  private PlatformViewRegistry registry;

  // The system channel used to communicate with the framework about platform views.
  private SimplePlatformViewsChannel platformViewsChannel;

  // The platform views.
  private final SparseArray<PlatformView> platformViews;

  // The platform view wrappers that are appended to FlutterView.
  //
  // These platform views use a PlatformViewLayer in the framework. This is different than
  // the platform views that use a TextureLayer.
  //
  // This distinction is necessary because a PlatformViewLayer allows to embed Android's
  // SurfaceViews in a Flutter app whereas the texture layer is unable to support such native views.
  //
  // If an entry in `platformViews` doesn't have an entry in this array, the platform view isn't
  // in the view hierarchy.
  //
  // This view provides a wrapper that applies scene builder operations to the platform view.
  // For example, a transform matrix, or setting opacity on the platform view layer.
  private final SparseArray<FlutterMutatorView> platformViewParent;

  // The platform view wrappers that are appended to FlutterView.
  //
  // These platform views use a TextureLayer in the framework. This is different than
  // the platform views that use a PlatformViewLayer.
  //
  // This is the default mode, and recommended for better performance.
  private final SparseArray<SimplePlatformViewWrapper> viewWrappers;

  // Used to acquire the original motion events using the motionEventIds.
  private final MotionEventTracker motionEventTracker;

  private final SimplePlatformViewsChannel.SimplePlatformViewsHandler channelHandler =
      new SimplePlatformViewsChannel.SimplePlatformViewsHandler() {

        @Override
        public void createForOpaqueHybridComposition(
            @NonNull SimplePlatformViewsChannel.PlatformViewCreationRequest request) {
          ensureValidRequest(request);
          final int viewId = request.viewId;
          if (viewWrappers.get(viewId) != null) {
            throw new IllegalStateException(
                "Trying to create an already created platform view, view id: " + viewId);
          }

          if (flutterView == null) {
            throw new IllegalStateException(
                "Flutter view is null. This means the platform views controller doesn't have an attached view, view id: "
                    + viewId);
          }

          final PlatformView platformView = createPlatformView(request, true);

          final View embeddedView = platformView.getView();
          if (embeddedView.getParent() != null) {
            throw new IllegalStateException(
                "The Android view returned from PlatformView#getView() was already added to a parent view.");
          }

          configureForOpaqueHybridComposition(platformView, request);
        }

        private void configureForOpaqueHybridComposition(
            @NonNull PlatformView platformView,
            @NonNull SimplePlatformViewsChannel.PlatformViewCreationRequest request) {
          Log.i(TAG, "Hosting opaque view in view hierarchy for platform view: " + request.viewId);

          final int physicalWidth = toPhysicalPixels(request.logicalWidth);
          final int physicalHeight = toPhysicalPixels(request.logicalHeight);
          SimplePlatformViewWrapper viewWrapper;
          viewWrapper = new SimplePlatformViewWrapper(context);
          // viewWrapper.setTouchProcessor(androidTouchProcessor);

          final FrameLayout.LayoutParams viewWrapperLayoutParams =
              new FrameLayout.LayoutParams(physicalWidth, physicalHeight);

          // Size and position the view wrapper.
          final int physicalTop = toPhysicalPixels(request.logicalTop);
          final int physicalLeft = toPhysicalPixels(request.logicalLeft);
          viewWrapperLayoutParams.topMargin = physicalTop;
          viewWrapperLayoutParams.leftMargin = physicalLeft;
          viewWrapper.setLayoutParams(viewWrapperLayoutParams);

          // Size the embedded view.
          final View embeddedView = platformView.getView();
          embeddedView.setLayoutParams(new FrameLayout.LayoutParams(physicalWidth, physicalHeight));

          // Accessibility in the embedded view is initially disabled because if a Flutter app
          // disabled accessibility in the first frame, the embedding won't receive an update to
          // disable accessibility since the embedding never received an update to enable it.
          // The AccessibilityBridge keeps track of the accessibility nodes, and handles the deltas
          // when the framework sends a new a11y tree to the embedding.
          // To prevent races, the framework populate the SemanticsNode after the platform view has
          // been created.
          embeddedView.setImportantForAccessibility(
              View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);

          // Add the embedded view to the wrapper.
          viewWrapper.addView(embeddedView);

          // Listen for focus changed in any subview, so the framework is notified when the platform
          // view is focused.
          viewWrapper.setOnDescendantFocusChangeListener(
              (v, hasFocus) -> {
                if (hasFocus) {
                  platformViewsChannel.invokeViewFocused(request.viewId);
                }
              });
          insertNewOpaqueHCView(flutterView, viewWrapper);
          viewWrappers.append(request.viewId, viewWrapper);
        }

        private void insertNewOpaqueHCView(
            FlutterView flutterView, SimplePlatformViewWrapper viewWrapper) {
          int index = 0;
          for (int i = 0; i < flutterView.getChildCount(); i++) {
            View child = flutterView.getChildAt(i);
            if (child instanceof SimplePlatformViewWrapper) {
              index = i + 1;
            }
          }
          flutterView.addView(viewWrapper, index);
        }

        @Override
        public void dispose(int viewId) {
          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Disposing unknown platform view with id: " + viewId);
            return;
          }
          platformViews.remove(viewId);

          try {
            platformView.dispose();
          } catch (RuntimeException exception) {
            Log.e(TAG, "Disposing platform view threw an exception", exception);
          }

          // The platform view is displayed using a TextureLayer and is inserted in the view
          // hierarchy.
          final SimplePlatformViewWrapper viewWrapper = viewWrappers.get(viewId);
          if (viewWrapper != null) {
            viewWrapper.removeAllViews();
            viewWrapper.release();
            viewWrapper.unsetOnDescendantFocusChangeListener();

            final ViewGroup wrapperParent = (ViewGroup) viewWrapper.getParent();
            if (wrapperParent != null) {
              wrapperParent.removeView(viewWrapper);
            }
            viewWrappers.remove(viewId);
            return;
          }
          // The platform view is displayed using a PlatformViewLayer.
          final FlutterMutatorView parentView = platformViewParent.get(viewId);
          if (parentView != null) {
            parentView.removeAllViews();
            parentView.unsetOnDescendantFocusChangeListener();

            final ViewGroup mutatorViewParent = (ViewGroup) parentView.getParent();
            if (mutatorViewParent != null) {
              mutatorViewParent.removeView(parentView);
            }
            platformViewParent.remove(viewId);
          }
        }

        @Override
        public void offset(int viewId, double top, double left) {
          if (usesVirtualDisplay(viewId)) {
            // Virtual displays don't need an accessibility offset.
            return;
          }
          // For platform views that use TextureView and are in the view hierarchy, set
          // an offset to the wrapper view.
          // This ensures that the accessibility highlights are drawn in the expected position on
          // screen.
          // This offset doesn't affect the position of the embeded view by itself since the GL
          // texture is positioned by the Flutter engine, which knows where to position different
          // types of layers.
          final SimplePlatformViewWrapper viewWrapper = viewWrappers.get(viewId);
          if (viewWrapper == null) {
            Log.e(TAG, "Setting offset for unknown platform view with id: " + viewId);
            return;
          }
          final int physicalTop = toPhysicalPixels(top);
          final int physicalLeft = toPhysicalPixels(left);
          final FrameLayout.LayoutParams layoutParams =
              (FrameLayout.LayoutParams) viewWrapper.getLayoutParams();
          layoutParams.topMargin = physicalTop;
          layoutParams.leftMargin = physicalLeft;
          viewWrapper.setLayoutParams(layoutParams);
        }

        @Override
        public void resize(
            @NonNull SimplePlatformViewsChannel.PlatformViewResizeRequest request,
            @NonNull SimplePlatformViewsChannel.PlatformViewBufferResized onComplete) {
          final int physicalWidth = toPhysicalPixels(request.newLogicalWidth);
          final int physicalHeight = toPhysicalPixels(request.newLogicalHeight);
          final int viewId = request.viewId;

          final PlatformView platformView = platformViews.get(viewId);
          final SimplePlatformViewWrapper viewWrapper = viewWrappers.get(viewId);
          if (platformView == null || viewWrapper == null) {
            Log.e(TAG, "Resizing unknown platform view with id: " + viewId);
            return;
          }

          final ViewGroup.LayoutParams viewWrapperLayoutParams = viewWrapper.getLayoutParams();
          viewWrapperLayoutParams.width = physicalWidth;
          viewWrapperLayoutParams.height = physicalHeight;
          viewWrapper.setLayoutParams(viewWrapperLayoutParams);

          final View embeddedView = platformView.getView();
          if (embeddedView != null) {
            final ViewGroup.LayoutParams embeddedViewLayoutParams = embeddedView.getLayoutParams();
            embeddedViewLayoutParams.width = physicalWidth;
            embeddedViewLayoutParams.height = physicalHeight;
            embeddedView.setLayoutParams(embeddedViewLayoutParams);
          }
          onComplete.run(
              new SimplePlatformViewsChannel.PlatformViewBufferSize(
                  toLogicalPixels(viewWrapper.getWidth()),
                  toLogicalPixels(viewWrapper.getHeight())));
        }

        @Override
        public void onTouch(@NonNull SimplePlatformViewsChannel.PlatformViewTouch touch) {
          final int viewId = touch.viewId;
          final float density = context.getResources().getDisplayMetrics().density;

          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Sending touch to an unknown view with id: " + viewId);
            return;
          }
          final View view = platformView.getView();
          if (view == null) {
            Log.e(TAG, "Sending touch to a null view with id: " + viewId);
            return;
          }
          final MotionEvent event = toMotionEvent(density, touch, false);
          view.dispatchTouchEvent(event);
        }

        @TargetApi(17)
        @Override
        public void setDirection(int viewId, int direction) {
          if (!validateDirection(direction)) {
            throw new IllegalStateException(
                "Trying to set unknown direction value: "
                    + direction
                    + "(view id: "
                    + viewId
                    + ")");
          }

          View embeddedView;

          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Setting direction to an unknown view with id: " + viewId);
            return;
          }
          embeddedView = platformView.getView();

          if (embeddedView == null) {
            Log.e(TAG, "Setting direction to a null view with id: " + viewId);
            return;
          }
          embeddedView.setLayoutDirection(direction);
        }

        @Override
        public void clearFocus(int viewId) {
          View embeddedView;

          final PlatformView platformView = platformViews.get(viewId);
          if (platformView == null) {
            Log.e(TAG, "Clearing focus on an unknown view with id: " + viewId);
            return;
          }
          embeddedView = platformView.getView();
          if (embeddedView == null) {
            Log.e(TAG, "Clearing focus on a null view with id: " + viewId);
            return;
          }
          embeddedView.clearFocus();
        }

      };

  /// Throws an exception if the SDK version is below minSdkVersion.
  private void enforceMinimumAndroidApiVersion(int minSdkVersion) {
    if (Build.VERSION.SDK_INT < minSdkVersion) {
      throw new IllegalStateException(
          "Trying to use platform views with API "
              + Build.VERSION.SDK_INT
              + ", required API level is: "
              + minSdkVersion);
    }
  }

  private void ensureValidRequest(
      @NonNull SimplePlatformViewsChannel.PlatformViewCreationRequest request) {
    if (!validateDirection(request.direction)) {
      throw new IllegalStateException(
          "Trying to create a view with unknown direction value: "
              + request.direction
              + "(view id: "
              + request.viewId
              + ")");
    }
  }

  // Creates a platform view based on `request`, performs configuration that's common to
  // all display modes, and adds it to `platformViews`.
  @TargetApi(19)
  @VisibleForTesting(otherwise = VisibleForTesting.PACKAGE_PRIVATE)
  public PlatformView createPlatformView(
      @NonNull SimplePlatformViewsChannel.PlatformViewCreationRequest request, boolean wrapContext) {
    final PlatformViewFactory viewFactory = getPlatformViewFactoryFromRegistryHack(request.viewType);
    if (viewFactory == null) {
      throw new IllegalStateException(
          "Trying to create a platform view of unregistered type: " + request.viewType);
    }

    Object createParams = null;
    if (request.params != null) {
      createParams = viewFactory.getCreateArgsCodec().decodeMessage(request.params);
    }

    // In some display modes, the context needs to be modified during display.
    // TODO(stuartmorgan): Make this wrapping unconditional if possible; for context see
    // https://github.com/flutter/flutter/issues/113449
    final Context mutableContext = wrapContext ? new MutableContextWrapper(context) : context;
    final PlatformView platformView =
        viewFactory.create(mutableContext, request.viewId, createParams);

    // Configure the view to match the requested layout direction.
    final View embeddedView = platformView.getView();
    if (embeddedView == null) {
      throw new IllegalStateException(
          "PlatformView#getView() returned null, but an Android view reference was expected.");
    }
    embeddedView.setLayoutDirection(request.direction);
    platformViews.put(request.viewId, platformView);
    maybeInvokeOnFlutterViewAttached(platformView);
    return platformView;
  }

  // Retrieve PlatformViewFactory from PlatformViewRegistry using reflection
  private PlatformViewFactory getPlatformViewFactoryFromRegistryHack(String viewType) {
    if (registry != null) {
      try {
        Class<?> subclass = registry.getClass();
        Method getFactoryMethod = null;
        Method[] methods = subclass.getDeclaredMethods();
        for (Method method : methods) {
          if (method.getParameterTypes().length == 1 && method.getParameterTypes()[0] == String.class &&
                  method.getReturnType() == PlatformViewFactory.class) {
            getFactoryMethod = method;
            break;
          }
        }
        if (getFactoryMethod != null) {
          getFactoryMethod.setAccessible(true);
          return (PlatformViewFactory) getFactoryMethod.invoke(registry, viewType);
        }
      } catch (Exception e) {
        Log.e(TAG, "Cannot get PlatformViewFactory for type " + viewType + " : " + e.toString());
        e.printStackTrace();
      }
    }
    return null;
  }

  @VisibleForTesting
  public MotionEvent toMotionEvent(
      float density, SimplePlatformViewsChannel.PlatformViewTouch touch, boolean usingVirtualDiplay) {
    MotionEventTracker.MotionEventId motionEventId =
        MotionEventTracker.MotionEventId.from(touch.motionEventId);
    MotionEvent trackedEvent = motionEventTracker.pop(motionEventId);

    // Pointer coordinates in the tracked events are global to FlutterView
    // framework converts them to be local to a widget, given that
    // motion events operate on local coords, we need to replace these in the tracked
    // event with their local counterparts.
    PointerProperties[] pointerProperties =
        parsePointerPropertiesList(touch.rawPointerPropertiesList)
            .toArray(new PointerProperties[touch.pointerCount]);
    PointerCoords[] pointerCoords =
        parsePointerCoordsList(touch.rawPointerCoords, density)
            .toArray(new PointerCoords[touch.pointerCount]);

    if (!usingVirtualDiplay && trackedEvent != null) {
      return MotionEvent.obtain(
          trackedEvent.getDownTime(),
          trackedEvent.getEventTime(),
          touch.action,
          touch.pointerCount,
          pointerProperties,
          pointerCoords,
          trackedEvent.getMetaState(),
          trackedEvent.getButtonState(),
          trackedEvent.getXPrecision(),
          trackedEvent.getYPrecision(),
          trackedEvent.getDeviceId(),
          trackedEvent.getEdgeFlags(),
          trackedEvent.getSource(),
          trackedEvent.getFlags());
    }

    // TODO (kaushikiska) : warn that we are potentially using an untracked
    // event in the platform views.
    return MotionEvent.obtain(
        touch.downTime.longValue(),
        touch.eventTime.longValue(),
        touch.action,
        touch.pointerCount,
        pointerProperties,
        pointerCoords,
        touch.metaState,
        touch.buttonState,
        touch.xPrecision,
        touch.yPrecision,
        touch.deviceId,
        touch.edgeFlags,
        touch.source,
        touch.flags);
  }

  public SimplePlatformViewsController() {
    viewWrappers = new SparseArray<>();
    platformViews = new SparseArray<>();
    platformViewParent = new SparseArray<>();
    motionEventTracker = MotionEventTracker.getInstance();
  }

  /**
   * Attaches this platform views controller to its input and output channels.
   *
   * @param context The base context that will be passed to embedded views created by this
   *     controller. This should be the context of the Activity hosting the Flutter application.
   * @param dartExecutor The dart execution context, which is used to set up a system channel.
   */
  public void attach(
      @Nullable Context context,
      PlatformViewRegistry platformViewRegistry,
      @NonNull BinaryMessenger dartExecutor) {
    if (this.context != null) {
      throw new AssertionError(
          "A PlatformViewsController can only be attached to a single output target.\n"
              + "attach was called while the PlatformViewsController was already attached.");
    }
    this.context = context;
    registry = platformViewRegistry;
    platformViewsChannel = new SimplePlatformViewsChannel(dartExecutor);
    platformViewsChannel.setPlatformViewsHandler(channelHandler);
  }

  /**
   * Detaches this platform views controller.
   *
   * <p>This is typically called when a Flutter applications moves to run in the background, or is
   * destroyed. After calling this the platform views controller will no longer listen to it's
   * previous messenger, and will not maintain references to the texture registry, context, and
   * messenger passed to the previous attach call.
   */
  @UiThread
  public void detach() {
    if (platformViewsChannel != null) {
      platformViewsChannel.setPlatformViewsHandler(null);
    }
    platformViewsChannel = null;
    context = null;
  }

  /**
   * Attaches the controller to a {@link FlutterView}.
   *
   * <p>When {@link io.flutter.embedding.android.FlutterFragment} is used, this method is called
   * after the device rotates since the FlutterView is recreated after a rotation.
   */
  public void attachToView(@NonNull FlutterView newFlutterView) {
    if (newFlutterView == flutterView) {
      return;
    }
    flutterView = newFlutterView;
    // Add wrapper for platform views that use GL texture.
    for (int index = 0; index < viewWrappers.size(); index++) {
      final SimplePlatformViewWrapper view = viewWrappers.valueAt(index);
      flutterView.addView(view);
    }
    // Add wrapper for platform views that are composed at the view hierarchy level.
    for (int index = 0; index < platformViewParent.size(); index++) {
      final FlutterMutatorView view = platformViewParent.valueAt(index);
      flutterView.addView(view);
    }
    // Notify platform views that they are now attached to a FlutterView.
    for (int index = 0; index < platformViews.size(); index++) {
      final PlatformView view = platformViews.valueAt(index);
      view.onFlutterViewAttached(flutterView);
    }
  }

  /**
   * Detaches the controller from {@link FlutterView}.
   *
   * <p>When {@link io.flutter.embedding.android.FlutterFragment} is used, this method is called
   * when the device rotates since the FlutterView is detached from the fragment. The next time the
   * fragment needs to be displayed, a new Flutter view is created, so attachToView is called again.
   */
  public void detachFromView() {
    // Remove wrapper for platform views that use GL texture.
    for (int index = 0; index < viewWrappers.size(); index++) {
      final SimplePlatformViewWrapper view = viewWrappers.valueAt(index);
      flutterView.removeView(view);
    }
    // Remove wrapper for platform views that are composed at the view hierarchy level.
    for (int index = 0; index < platformViewParent.size(); index++) {
      final FlutterMutatorView view = platformViewParent.valueAt(index);
      flutterView.removeView(view);
    }

    flutterView = null;

    // Notify that the platform view have been detached from FlutterView.
    for (int index = 0; index < platformViews.size(); index++) {
      final PlatformView view = platformViews.valueAt(index);
      view.onFlutterViewDetached();
    }
  }

  private void maybeInvokeOnFlutterViewAttached(PlatformView view) {
    if (flutterView == null) {
      Log.i(TAG, "null flutterView");
      // There is currently no FlutterView that we are attached to.
      return;
    }
    view.onFlutterViewAttached(flutterView);
  }

  @Override
  public void attachAccessibilityBridge(@NonNull AccessibilityBridge accessibilityBridge) {
  }

  @Override
  public void detachAccessibilityBridge() {
  }

  public PlatformViewRegistry getRegistry() {
    return registry;
  }

  public void onPreEngineRestart() {
    disposeAllViews();
  }

  @Override
  @Nullable
  public View getPlatformViewById(int viewId) {
    final PlatformView platformView = platformViews.get(viewId);
    if (platformView == null) {
      return null;
    }
    return platformView.getView();
  }

  @Override
  public boolean usesVirtualDisplay(int id) {
    return false;
  }

  private static boolean validateDirection(int direction) {
    return direction == View.LAYOUT_DIRECTION_LTR || direction == View.LAYOUT_DIRECTION_RTL;
  }

  @SuppressWarnings("unchecked")
  private static List<PointerProperties> parsePointerPropertiesList(Object rawPropertiesList) {
    List<Object> rawProperties = (List<Object>) rawPropertiesList;
    List<PointerProperties> pointerProperties = new ArrayList<>();
    for (Object o : rawProperties) {
      pointerProperties.add(parsePointerProperties(o));
    }
    return pointerProperties;
  }

  @SuppressWarnings("unchecked")
  private static PointerProperties parsePointerProperties(Object rawProperties) {
    List<Object> propertiesList = (List<Object>) rawProperties;
    PointerProperties properties = new PointerProperties();
    properties.id = (int) propertiesList.get(0);
    properties.toolType = (int) propertiesList.get(1);
    return properties;
  }

  @SuppressWarnings("unchecked")
  private static List<PointerCoords> parsePointerCoordsList(Object rawCoordsList, float density) {
    List<Object> rawCoords = (List<Object>) rawCoordsList;
    List<PointerCoords> pointerCoords = new ArrayList<>();
    for (Object o : rawCoords) {
      pointerCoords.add(parsePointerCoords(o, density));
    }
    return pointerCoords;
  }

  @SuppressWarnings("unchecked")
  private static PointerCoords parsePointerCoords(Object rawCoords, float density) {
    List<Object> coordsList = (List<Object>) rawCoords;
    PointerCoords coords = new PointerCoords();
    coords.orientation = (float) (double) coordsList.get(0);
    coords.pressure = (float) (double) coordsList.get(1);
    coords.size = (float) (double) coordsList.get(2);
    coords.toolMajor = (float) (double) coordsList.get(3) * density;
    coords.toolMinor = (float) (double) coordsList.get(4) * density;
    coords.touchMajor = (float) (double) coordsList.get(5) * density;
    coords.touchMinor = (float) (double) coordsList.get(6) * density;
    coords.x = (float) (double) coordsList.get(7) * density;
    coords.y = (float) (double) coordsList.get(8) * density;
    return coords;
  }

  private float getDisplayDensity() {
    return context.getResources().getDisplayMetrics().density;
  }

  private int toPhysicalPixels(double logicalPixels) {
    return (int) Math.round(logicalPixels * getDisplayDensity());
  }

  private int toLogicalPixels(double physicalPixels, float displayDensity) {
    return (int) Math.round(physicalPixels / displayDensity);
  }

  private int toLogicalPixels(double physicalPixels) {
    return toLogicalPixels(physicalPixels, getDisplayDensity());
  }

  private void disposeAllViews() {
    while (platformViews.size() > 0) {
      final int viewId = platformViews.keyAt(0);
      // Dispose deletes the entry from platformViews and clears associated resources.
      channelHandler.dispose(viewId);
    }
  }

  /**
   * Disposes a single
   *
   * @param viewId the PlatformView ID.
   */
  @VisibleForTesting
  public void disposePlatformView(int viewId) {
    channelHandler.dispose(viewId);
  }

  public void attachToFlutterRenderer(@NonNull FlutterRenderer flutterRenderer) {
    androidTouchProcessor = new AndroidTouchProcessor(flutterRenderer, /*trackMotionEvents=*/ true);
  }

}
