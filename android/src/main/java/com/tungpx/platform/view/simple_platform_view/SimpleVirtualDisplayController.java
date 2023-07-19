package com.tungpx.platform.view.simple_platform_view;

import static android.view.View.OnFocusChangeListener;

import android.annotation.TargetApi;
import android.content.Context;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.util.DisplayMetrics;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.View;
import android.view.ViewTreeObserver;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;

import io.flutter.plugin.platform.PlatformView;
import io.flutter.view.TextureRegistry;

@TargetApi(20)
class SimpleVirtualDisplayController {
    private static String TAG = "VirtualDisplayController";

    public static SimpleVirtualDisplayController create(
            Context context,
            SimpleAccessibilityEventsDelegate accessibilityEventsDelegate,
            PlatformView view,
            TextureRegistry.SurfaceTextureEntry textureEntry,
            int width,
            int height,
            int viewId,
            Object createParams,
            OnFocusChangeListener focusChangeListener) {

        DisplayMetrics metrics = context.getResources().getDisplayMetrics();
        if (width == 0 || height == 0) {
            return null;
        }

        // Virtual Display crashes for some PlatformViews if the width or height is bigger
        // than the physical screen size. We have tried to clamp or scale down the size to prevent
        // the crash, but both solutions lead to unwanted behavior because the
        // AndroidPlatformView(https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/widgets/platform_view.dart#L677) widget doesn't
        // scale or clamp, which leads to a mismatch between the size of the widget and the size of
        // virtual display.
        // This mismatch leads to some test failures: https://github.com/flutter/flutter/issues/106750
        // TODO(cyanglaz): find a way to prevent the crash without introducing size mistach betewen
        // virtual display and AndroidPlatformView widget.
        // https://github.com/flutter/flutter/issues/93115
        textureEntry.surfaceTexture().setDefaultBufferSize(width, height);
        Surface surface = new Surface(textureEntry.surfaceTexture());
        DisplayManager displayManager =
                (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);

        int densityDpi = context.getResources().getDisplayMetrics().densityDpi;
        VirtualDisplay virtualDisplay =
                displayManager.createVirtualDisplay("flutter-vd", width, height, densityDpi, surface, 0);

        if (virtualDisplay == null) {
            return null;
        }
        SimpleVirtualDisplayController controller =
                new SimpleVirtualDisplayController(
                        context,
                        accessibilityEventsDelegate,
                        virtualDisplay,
                        view,
                        surface,
                        textureEntry,
                        focusChangeListener,
                        viewId,
                        createParams);
        controller.bufferWidth = width;
        controller.bufferHeight = height;
        return controller;
    }

    @VisibleForTesting SingleViewPresentation presentation;

    private final Context context;
    private final SimpleAccessibilityEventsDelegate accessibilityEventsDelegate;
    private final int densityDpi;
    private final TextureRegistry.SurfaceTextureEntry textureEntry;
    private final OnFocusChangeListener focusChangeListener;
    private final Surface surface;

    private VirtualDisplay virtualDisplay;
    private int bufferWidth;
    private int bufferHeight;

    private SimpleVirtualDisplayController(
            Context context,
            SimpleAccessibilityEventsDelegate accessibilityEventsDelegate,
            VirtualDisplay virtualDisplay,
            PlatformView view,
            Surface surface,
            TextureRegistry.SurfaceTextureEntry textureEntry,
            OnFocusChangeListener focusChangeListener,
            int viewId,
            Object createParams) {
        this.context = context;
        this.accessibilityEventsDelegate = accessibilityEventsDelegate;
        this.textureEntry = textureEntry;
        this.focusChangeListener = focusChangeListener;
        this.surface = surface;
        this.virtualDisplay = virtualDisplay;
        densityDpi = context.getResources().getDisplayMetrics().densityDpi;
        presentation =
                new SingleViewPresentation(
                        context,
                        this.virtualDisplay.getDisplay(),
                        view,
                        accessibilityEventsDelegate,
                        viewId,
                        focusChangeListener);
        presentation.show();
    }

    public int getBufferWidth() {
        return bufferWidth;
    }

    public int getBufferHeight() {
        return bufferHeight;
    }

    public void resize(final int width, final int height, final Runnable onNewSizeFrameAvailable) {
        boolean isFocused = getView().isFocused();
        final SingleViewPresentation.PresentationState presentationState = presentation.detachState();
        // We detach the surface to prevent it being destroyed when releasing the vd.
        //
        // setSurface is only available starting API 20. We could support API 19 by re-creating a new
        // SurfaceTexture here. This will require refactoring the TextureRegistry to allow recycling
        // texture
        // entry IDs.
        virtualDisplay.setSurface(null);
        virtualDisplay.release();

        bufferWidth = width;
        bufferHeight = height;
        textureEntry.surfaceTexture().setDefaultBufferSize(width, height);
        DisplayManager displayManager =
                (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
        virtualDisplay =
                displayManager.createVirtualDisplay("flutter-vd", width, height, densityDpi, surface, 0);

        final View embeddedView = getView();
        // There's a bug in Android version older than O where view tree observer onDrawListeners don't
        // get properly
        // merged when attaching to window, as a workaround we register the on draw listener after the
        // view is attached.
        embeddedView.addOnAttachStateChangeListener(
                new View.OnAttachStateChangeListener() {
                    @Override
                    public void onViewAttachedToWindow(View v) {
                        OneTimeOnDrawListener.schedule(
                                embeddedView,
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        // We need some delay here until the frame propagates through the vd surface to
                                        // the texture,
                                        // 128ms was picked pretty arbitrarily based on trial and error.
                                        // As long as we invoke the runnable after a new frame is available we avoid the
                                        // scaling jank
                                        // described in: https://github.com/flutter/flutter/issues/19572
                                        // We should ideally run onNewSizeFrameAvailable ASAP to make the embedded view
                                        // more responsive
                                        // following a resize.
                                        embeddedView.postDelayed(onNewSizeFrameAvailable, 128);
                                    }
                                });
                        embeddedView.removeOnAttachStateChangeListener(this);
                    }

                    @Override
                    public void onViewDetachedFromWindow(View v) {}
                });

        // Create a new SingleViewPresentation and show() it before we cancel() the existing
        // presentation. Calling show() and cancel() in this order fixes
        // https://github.com/flutter/flutter/issues/26345 and maintains seamless transition
        // of the contents of the presentation.
        SingleViewPresentation newPresentation =
                new SingleViewPresentation(
                        context,
                        virtualDisplay.getDisplay(),
                        accessibilityEventsDelegate,
                        presentationState,
                        focusChangeListener,
                        isFocused);
        newPresentation.show();
        presentation.cancel();
        presentation = newPresentation;
    }

    public void dispose() {
        // Fix rare crash on HuaWei device described in: https://github.com/flutter/engine/pull/9192
        presentation.cancel();
        presentation.detachState();
        virtualDisplay.release();
        textureEntry.release();
    }

    /** See {@link PlatformView#onFlutterViewAttached(View)} */
    /*package*/ void onFlutterViewAttached(@NonNull View flutterView) {
        if (presentation == null || presentation.getView() == null) {
            return;
        }
        presentation.getView().onFlutterViewAttached(flutterView);
    }

    /** See {@link PlatformView#onFlutterViewDetached()} */
    /*package*/ void onFlutterViewDetached() {
        if (presentation == null || presentation.getView() == null) {
            return;
        }
        presentation.getView().onFlutterViewDetached();
    }

    /*package*/ void onInputConnectionLocked() {
        if (presentation == null || presentation.getView() == null) {
            return;
        }
        presentation.getView().onInputConnectionLocked();
    }

    /*package*/ void onInputConnectionUnlocked() {
        if (presentation == null || presentation.getView() == null) {
            return;
        }
        presentation.getView().onInputConnectionUnlocked();
    }

    public View getView() {
        if (presentation == null) return null;
        PlatformView platformView = presentation.getView();
        return platformView.getView();
    }

    /** Dispatches a motion event to the presentation for this controller. */
    public void dispatchTouchEvent(MotionEvent event) {
        if (presentation == null) return;
        presentation.dispatchTouchEvent(event);
    }

    static class OneTimeOnDrawListener implements ViewTreeObserver.OnDrawListener {
        static void schedule(View view, Runnable runnable) {
            OneTimeOnDrawListener listener = new OneTimeOnDrawListener(view, runnable);
            view.getViewTreeObserver().addOnDrawListener(listener);
        }

        final View mView;
        Runnable mOnDrawRunnable;

        OneTimeOnDrawListener(View view, Runnable onDrawRunnable) {
            this.mView = view;
            this.mOnDrawRunnable = onDrawRunnable;
        }

        @Override
        public void onDraw() {
            if (mOnDrawRunnable == null) {
                return;
            }
            mOnDrawRunnable.run();
            mOnDrawRunnable = null;
            mView.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            mView.getViewTreeObserver().removeOnDrawListener(OneTimeOnDrawListener.this);
                        }
                    });
        }
    }
}
