package com.tungpx.platform.view.simple_platform_view;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.Looper;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.view.ViewTreeObserver;
import android.view.accessibility.AccessibilityEvent;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.util.ViewUtils;

/**
 * Base class for wraps a platform view to intercept gestures and project this view onto a {@link
 * SurfaceTexture}.
 */
public class SimplePlatformViewWrapper extends FrameLayout {

  private int prevLeft;
  private int prevTop;
  private int left;
  private int top;
  private int bufferWidth;
  private int bufferHeight;
  private SurfaceTexture tx;
  private Surface surface;
  private AndroidTouchProcessor touchProcessor;
  private Matrix matrix;

  @Nullable @VisibleForTesting ViewTreeObserver.OnGlobalFocusChangeListener activeFocusListener;

  public SimplePlatformViewWrapper(Context context) {
    super(context);
  }

  public SimplePlatformViewWrapper(Context context, AttributeSet attrs) {
    super(context, attrs);
  }

  public SimplePlatformViewWrapper(Context context, AttributeSet attrs, int defStyle) {
    super(context, attrs, defStyle);
  }

  public void setMatrix(Matrix value) {
    matrix = value;
    shouldUpdateSize();
  }

  void getMatrixScale(float[] scale) {
    if (matrix != null) {
      float[] matrixValues = new float[9];
      matrix.getValues(matrixValues);
      scale[0] = matrixValues[Matrix.MSCALE_X];
      scale[1] = matrixValues[Matrix.MSCALE_Y];
      return;
    }
    scale[0] = 1.0f;
    scale[1] = 1.0f;
  }

  @Override
  public void dispatchDraw(Canvas canvas) {
    Matrix currMatrix = matrix;
    if (currMatrix != null) {
      // Apply the transforms on the child canvas
      canvas.save();
      canvas.concat(currMatrix);
      super.dispatchDraw(canvas);
      canvas.restore();
    } else {
      super.dispatchDraw(canvas);
    }
  }

  /**
   * Sets the touch processor that allows to intercept gestures.
   *
   * @param newTouchProcessor The touch processor.
   */
  public void setTouchProcessor(@Nullable AndroidTouchProcessor newTouchProcessor) {
    touchProcessor = newTouchProcessor;
  }

  /**
   * Sets the layout parameters for this view.
   *
   * @param params The new parameters.
   */
  public void setLayoutParams(@NonNull LayoutParams params) {
    super.setLayoutParams(params);

    left = params.leftMargin;
    top = params.topMargin;
  }

  /**
   * Sets the size of the image buffer.
   *
   * @param width The width of the screen buffer.
   * @param height The height of the screen buffer.
   */
  public void setBufferSize(int width, int height) {
    bufferWidth = width;
    bufferHeight = height;
    if (tx != null) {
      tx.setDefaultBufferSize(width, height);
    }
  }

  private void updateViewSize() {
    float scaleX = 1.0f;
    float scaleY = 1.0f;
    if (matrix != null) {
      float[] scale = new float[2];
      getMatrixScale(scale);
      scaleX = scale[0];
      scaleY = scale[1];
    }
    if (getChildCount() == 1) {
      View child = getChildAt(0);
      ViewGroup.LayoutParams childParams = child.getLayoutParams();
      ViewGroup.LayoutParams params = getLayoutParams();
      if (params instanceof FrameLayout.LayoutParams) {
        FrameLayout.LayoutParams mParams = (FrameLayout.LayoutParams) params;
        int width = childParams.width;
        int height = childParams.height;
        if (scaleX != 1.0f) {
          width = Math.round(width * scaleX);
        }
        if (scaleY != 1.0f) {
          height = Math.round(height * scaleY);
        }
        if (width != mParams.width || height != mParams.height) {
          mParams.width = width;
          mParams.height = height;
          setLayoutParams(mParams);
        }
      }
    }
  }

  public void shouldUpdateSize() {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      updateViewSize();
    } else {
      final Runnable runnable = new Runnable() {
        @Override
        public void run() {
          updateViewSize();
        }
      };
      Handler mainHandler = new Handler(Looper.getMainLooper());
      mainHandler.post(runnable);
    }
  }

  /** Returns the image buffer width. */
  public int getBufferWidth() {
    return bufferWidth;
  }

  /** Returns the image buffer height. */
  public int getBufferHeight() {
    return bufferHeight;
  }

  /** Releases the surface. */
  public void release() {
    tx = null;
    if (surface != null) {
      surface.release();
      surface = null;
    }
  }

  @Override
  public boolean onInterceptTouchEvent(@NonNull MotionEvent event) {
    return true;
  }

  @Override
  public boolean requestSendAccessibilityEvent(View child, AccessibilityEvent event) {
    final View embeddedView = getChildAt(0);
    if (embeddedView != null
        && embeddedView.getImportantForAccessibility()
            == View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS) {
      return false;
    }
    // Forward the request only if the embedded view is in the Flutter accessibility tree.
    // The embedded view may be ignored when the framework doesn't populate a SemanticNode
    // for the current platform view.
    // See AccessibilityBridge for more.
    return super.requestSendAccessibilityEvent(child, event);
  }

  /** Used on Android O+*/
  @SuppressLint("NewApi")
  @Override
  public void onDescendantInvalidated(@NonNull View child, @NonNull View target) {
    super.onDescendantInvalidated(child, target);
    invalidate();
  }

  @Override
  public ViewParent invalidateChildInParent(int[] location, Rect dirty) {
    invalidate();
    return super.invalidateChildInParent(location, dirty);
  }

  @Override
  @SuppressLint("ClickableViewAccessibility")
  public boolean onTouchEvent(@NonNull MotionEvent event) {
    if (touchProcessor == null) {
      return super.onTouchEvent(event);
    }
    final Matrix screenMatrix = new Matrix();
    switch (event.getAction()) {
      case MotionEvent.ACTION_DOWN:
        prevLeft = left;
        prevTop = top;
        screenMatrix.postTranslate(left, top);
        break;
      case MotionEvent.ACTION_MOVE:
        // While the view is dragged, use the left and top positions as
        // they were at the moment the touch event fired.
        screenMatrix.postTranslate(prevLeft, prevTop);
        prevLeft = left;
        prevTop = top;
        break;
      case MotionEvent.ACTION_UP:
      default:
        screenMatrix.postTranslate(left, top);
        break;
    }
    return touchProcessor.onTouchEvent(event, screenMatrix);
  }

  public void setOnDescendantFocusChangeListener(@NonNull OnFocusChangeListener userFocusListener) {
    unsetOnDescendantFocusChangeListener();
    final ViewTreeObserver observer = getViewTreeObserver();
    if (observer.isAlive() && activeFocusListener == null) {
      activeFocusListener =
          new ViewTreeObserver.OnGlobalFocusChangeListener() {
            @Override
            public void onGlobalFocusChanged(View oldFocus, View newFocus) {
              userFocusListener.onFocusChange(
                  SimplePlatformViewWrapper.this, ViewUtils.childHasFocus(SimplePlatformViewWrapper.this));
            }
          };
      observer.addOnGlobalFocusChangeListener(activeFocusListener);
    }
  }

  public void unsetOnDescendantFocusChangeListener() {
    final ViewTreeObserver observer = getViewTreeObserver();
    if (observer.isAlive() && activeFocusListener != null) {
      final ViewTreeObserver.OnGlobalFocusChangeListener currFocusListener = activeFocusListener;
      activeFocusListener = null;
      observer.removeOnGlobalFocusChangeListener(currFocusListener);
    }
  }
}
