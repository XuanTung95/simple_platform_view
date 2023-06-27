import Flutter;
import UIKit

/// Manage platform views
class SimpleFlutterPlatformViewsController {
    private var factories: [String: FlutterPlatformViewFactory] = [:]
    private var gestureRecognizersBlockingPolicies: [String: FlutterPlatformViewGestureRecognizersBlockingPolicy] = [:]
    private var views: [Int64: FlutterPlatformView] = [:]
    var rootViews: [Int64: FlutterTouchInterceptingView] = [:]
    private var touchInterceptors: [Int64: FlutterTouchInterceptingView] = [:]
    private var flutterViewContainer: SimpleFlutterViewContainer?
    private var flutterViewController: FlutterViewController?
    private var backgroundColor: UIColor?
    
    func registerViewFactory(_ factory: FlutterPlatformViewFactory, withId factoryId: String, gestureRecognizerBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {
        let idString = factoryId
        let factoryObject = factory
        factories[idString] = factoryObject
        gestureRecognizersBlockingPolicies[idString] = gestureRecognizerBlockingPolicy
    }
    
    func getFlutterViewController() -> FlutterViewController? {
        return flutterViewController
    }
    
    func setFlutterViewController(_ flutterViewController: FlutterViewController) {
        self.flutterViewController = flutterViewController
    }
    
    /// Dispose a platform view
    func onDispose(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:];
        let viewId: Int64 = args["id"] as? Int64 ?? -1;
        
        if (views[viewId] == nil || viewId == -1) {
            result(FlutterError(code: "unknown_view",
                                message: "trying to dispose an unknown",
                                details: "view id: '\(viewId)'"))
            return;
        }
        disposeByViewId(viewId: viewId);
        result(nil);
    }
    
    private func disposeByViewId(viewId: Int64) {
        let rootView = rootViews[viewId];
        rootView?.removeFromSuperview();
        views.removeValue(forKey: viewId);
        touchInterceptors.removeValue(forKey: viewId);
        rootViews.removeValue(forKey: viewId);
    }
    
    /// Create new platform view
    func onCreate(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:];
        let viewId: Int64 = args["id"] as? Int64 ?? -1;
        let viewTypeString = args["viewType"] as? String ?? "";
        let width: Double? = args["width"] as? Double;
        let height: Double? = args["height"] as? Double;
        
        if views[viewId] != nil || viewId == -1 {
            result(FlutterError(code: "recreating_view",
                                message: "Trying to create an already created view.",
                                details: "View ID: '\(viewId)'"))
            return
        }
        
        let factory = factories[viewTypeString];
        if (factory == nil) {
            result(FlutterError(code: "unregistered_view_type",
                                message: "A UIKitView widget is trying to create a PlatformView with an unregistered type: < \(viewTypeString) >",
                                details: "If you are the author of the PlatformView, make sure `registerViewFactory` is invoked.\nSee: https://docs.flutter.dev/development/platform-integration/platform-views#on-the-platform-side-1 for more details.\nIf you are not the author of the PlatformView, make sure to call `GeneratedPluginRegistrant.register`."))
            return;
        }
        
        if (width == nil || height == nil) {
            result(FlutterError(code: "invalid size",
                                message: "trying to create view with width = \(String(describing: width)) height = \(String(describing: height))",
                                details: "view id: '\(viewId)'"))
            return;
        }
        
        var params: Any? = nil;
        if let codec = factory?.createArgsCodec?() {
            if (args["params"] != nil) {
                let paramsData = args["params"] as? FlutterStandardTypedData;
                if (paramsData != nil) {
                    params = codec.decode(paramsData!.data);
                }
            }
        } else {
            // The method returned nil
        }
        let embeddedView: FlutterPlatformView = factory!.create(withFrame: .zero,
                                                                viewIdentifier: viewId,
                                                                arguments: params);
        let platformView: UIView = embeddedView.view();
        platformView.accessibilityIdentifier = "platform_view[\(viewId)]";
        views[viewId] = embeddedView;
        
        let frame = CGRect(x: 0, y: 0, width: width!, height: height!)
        
        var touchInterceptor: FlutterTouchInterceptingView = FlutterTouchInterceptingView(
            frame: frame,
            embeddedView: platformView,
            platformViewsController: self,
            gestureRecognizersBlockingPolicy: gestureRecognizersBlockingPolicies[viewTypeString]!
        )
        touchInterceptors[viewId] = touchInterceptor
        
        /* TODO:
         ChildClippingView* clipping_view =
         [[[ChildClippingView alloc] initWithFrame:CGRectZero] autorelease];
         [clipping_view addSubview:touch_interceptor];
         */
        
        let rootView = touchInterceptor;
        rootViews[viewId] = rootView;
        if (flutterViewContainer != nil) {
            flutterViewContainer!.addNewPlatformView(rootView)
        }
        result(nil);
    }
    
    /// platform view continue to handle gesture
    public func onAcceptGesture(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:];
        let viewId: Int64 = args["id"] as? Int64 ?? -1;
        if viewId == -1 || views[viewId] == nil {
            result(FlutterError(code: "unknown_view",
                                message: "Trying to set gesture state for an unknown view",
                                details: "view id: '\(viewId)'"))
            return
        }
        
        if let view = touchInterceptors[viewId] {
            view.releaseGesture()
        }
        
        result(nil)
    }
    
    /// gesture is handled by flutter
    public func onRejectGesture(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:];
        let viewId: Int64 = args["id"] as? Int64 ?? -1;
        
        if (viewId == -1 || views[viewId] == nil) {
            result(FlutterError(code: "unknown_view",
                                message: "trying to set gesture state for an unknown view",
                                details: "view id: '\(viewId)'"))
            return;
        }
        
        if let view = touchInterceptors[viewId] {
            view.blockGesture()
        }
        
        result(nil);
    }
    
    /// Resize platform view
    public func resize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:];
        let viewId: Int64 = args["id"] as? Int64 ?? -1;
        let width: Double? = args["width"] as? Double;
        let height: Double? = args["height"] as? Double;
        let top: Double? = args["top"] as? Double;
        let left: Double? = args["left"] as? Double;
        
        if (width == nil || height == nil) {
            result(FlutterError(code: "invalid size",
                                message: "trying to resize with = \(String(describing: width)) height = \(String(describing: height))",
                                details: "view id: '\(viewId)'"))
            return;
        }
        if (viewId == -1 || views[viewId] == nil) {
            result(FlutterError(code: "unknown_view",
                                message: "trying to set gesture state for an unknown view",
                                details: "view id: '\(viewId)'"))
            return;
        }
        let view = rootViews[viewId];
        if (view != nil) {
            view?.resize(width: width!, height: height!, left: left, top: top)
        }
        let ret: [String: Any] = [
            "width": width!,
            "height": height!,
        ]
        result(ret);
    }
    
    /// Change platform view position
    public func offset(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:];
        let viewId: Int64 = args["id"] as? Int64 ?? -1;
        let top: Double? = args["top"] as? Double;
        let left: Double? = args["left"] as? Double;
        
        if (top == nil || left == nil) {
            result(FlutterError(code: "invalid offset",
                                message: "trying to set offset top = \(String(describing: top)) left = \(String(describing: left))",
                                details: "view id: '\(viewId)'"))
            return;
        }
        if (viewId == -1 || views[viewId] == nil) {
            result(FlutterError(code: "unknown_view",
                                message: "trying to set gesture state for an unknown view",
                                details: "view id: '\(viewId)'"))
            return;
        }
        
        let view = rootViews[viewId];
        if (view != nil) {
            view!.setOffset(left: left!, top: top!)
        }
        result(nil);
    }
    
    public func getRootView(_ viewId: Int64) -> UIView? {
        return rootViews[viewId];
    }
    
    public func setFlutterViewContainer(_ flutterViewContainer: SimpleFlutterViewContainer) {
        self.flutterViewContainer = flutterViewContainer;
        if (backgroundColor != nil) {
            flutterViewContainer.backgroundColor = backgroundColor!;
        }
    }
    
    // Set background color for FlutterViewContainer
    public func setBackgroundColor(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:];
        let colorValue: Int64? = args["color"] as? Int64;
        if (colorValue != nil) {
            let color = getColorFromInt(colorValue!);
            backgroundColor = color;
            if (flutterViewContainer != nil) {
                flutterViewContainer?.backgroundColor = color;
            }
        }
        result(nil);
    }
    
    private func getColorFromInt(_ intValue: Int64) -> UIColor {
        let alpha = CGFloat((intValue & 0xFF000000) >> 24) / 255.0
        let red = CGFloat((intValue & 0x00FF0000) >> 16) / 255.0
        let green = CGFloat((intValue & 0x0000FF00) >> 8) / 255.0
        let blue = CGFloat(intValue & 0x000000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Clean platform views after hot restart
    public func performHotRestart(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let keys = Array(views.keys)
        for viewId in keys {
            disposeByViewId(viewId: viewId)
        }
        result(nil);
    }
}
