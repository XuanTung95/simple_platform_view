package com.tungpx.platform.view.simple_platform_view_example;

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
