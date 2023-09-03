package com.tungpx.platform.view.simple_platform_view;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class SimplePlatformViewContainer extends FrameLayout {
    public SimplePlatformViewContainer(@NonNull Context context) {
        super(context);
    }

    public SimplePlatformViewContainer(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public SimplePlatformViewContainer(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }
}
