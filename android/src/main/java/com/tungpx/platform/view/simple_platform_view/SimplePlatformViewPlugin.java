package com.tungpx.platform.view.simple_platform_view;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformViewRegistry;

/** SimplePlatformViewPlugin */
public class SimplePlatformViewPlugin implements FlutterPlugin, ActivityAware {
  @Nullable private Lifecycle lifecycle;

  FlutterEngine.EngineLifecycleListener engineListener = new FlutterEngine.EngineLifecycleListener() {
    @Override
    public void onPreEngineRestart() {
      platformViewsController.onPreEngineRestart();
    }

    @Override
    public void onEngineWillDestroy() {
    }
  };

  private final DefaultLifecycleObserver lifecycleObserver = new DefaultLifecycleObserver() {
    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {
    }

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {
      initFlutterView();
    }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
      initFlutterView();
    }

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {
    }

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
    }

    void initFlutterView() {
      FlutterView flutterView = getFlutterViewFromActivity(activity);
      if (flutterView != null) {
        platformViewsController.attachToView(flutterView);
      }
    }
  };

  @Nullable Activity activity;

  private SimplePlatformViewsController platformViewsController;

  // static private PlatformViewRegistryImpl platformViewRegistry = new PlatformViewRegistryImpl();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    PlatformViewRegistry viewRegistry = flutterPluginBinding.getPlatformViewRegistry();
    platformViewsController = new SimplePlatformViewsController();
    platformViewsController.attach(flutterPluginBinding.getApplicationContext(), viewRegistry,
            flutterPluginBinding.getBinaryMessenger());
    flutterPluginBinding.getFlutterEngine().addEngineLifecycleListener(engineListener);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    platformViewsController.detach();
  }

  // ActivityAware

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    activity = binding.getActivity();
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
    lifecycle.addObserver(lifecycleObserver);
  }

  private FlutterView getFlutterViewFromActivity(Activity activity) {
    View view = activity.findViewById(android.R.id.content);
    return findFlutterView(view);
  }

  private FlutterView findFlutterView(View parentView) {
    if (parentView == null) {
      return null;
    }
    if (parentView instanceof FlutterView) {
      return (FlutterView) parentView;
    }
    if (parentView instanceof ViewGroup) {
      ViewGroup viewGroup = (ViewGroup) parentView;
      int childCount = viewGroup.getChildCount();
      for (int i = 0; i < childCount; i++) {
        View childView = viewGroup.getChildAt(i);
        FlutterView foundView = findFlutterView(childView);
        if (foundView != null) {
          return foundView;
        }
      }
    }
    return null;
  }

  @Override
  public void onDetachedFromActivity() {
    lifecycle = null;
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

}
