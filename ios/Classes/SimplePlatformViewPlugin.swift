import Flutter;
import UIKit

public class SimplePlatformViewPlugin: NSObject, FlutterPlugin {
    
    private static let platformController = SimpleFlutterPlatformViewsController()
    private static var fakePluginRegistry: FakeFlutterPluginRegistry?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tungpx/simple_platform_views", binaryMessenger: registrar.messenger())
        let instance = SimplePlatformViewPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    // Create a fake FlutterPluginRegistry to register a view factory into both the Flutter framework
    // and the SimplePlatformViewPlugin.
    public static func createFakeFlutterPluginRegistry(realPluginRegistry: FlutterPluginRegistry) -> FlutterPluginRegistry {
        let ret = FakeFlutterPluginRegistry(realPluginRegistry: realPluginRegistry)
        fakePluginRegistry = ret;
        return ret;
    }
    
    // Register a view factory into SimplePlatformViewPlugin
    public static func registerViewFactory(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {
        platformController.registerViewFactory(factory, withId: factoryId, gestureRecognizerBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyEager)
    }
    
    // Register a view factory into SimplePlatformViewPlugin
    public static func registerViewFactory(_ factory: FlutterPlatformViewFactory, withId factoryId: String, gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {
        platformController.registerViewFactory(factory, withId: factoryId, gestureRecognizerBlockingPolicy: gestureRecognizersBlockingPolicy)
    }
    
    private func findFlutterViewController(in viewController: UIViewController) -> FlutterViewController? {
        if let flutterViewController = viewController as? FlutterViewController {
            return flutterViewController
        }
        
        if let navigationController = viewController as? UINavigationController {
            for childViewController in navigationController.viewControllers {
                if let flutterViewController = findFlutterViewController(in: childViewController) {
                    return flutterViewController
                }
            }
        }
        
        if let tabBarController = viewController as? UITabBarController {
            for childViewController in tabBarController.viewControllers ?? [] {
                if let flutterViewController = findFlutterViewController(in: childViewController) {
                    return flutterViewController
                }
            }
        }
        
        if let presentedViewController = viewController.presentedViewController {
            if let flutterViewController = findFlutterViewController(in: presentedViewController) {
                return flutterViewController
            }
        }
        
        for childViewController in viewController.children {
            if let flutterViewController = findFlutterViewController(in: childViewController) {
                return flutterViewController
            }
        }
        
        return nil
    }
    
    private func findFirstFlutterViewController() -> FlutterViewController? {
        guard let window = UIApplication.shared.windows.first else {
            return nil
        }
        
        guard let rootViewController = window.rootViewController else {
            return nil
        }
        
        return findFlutterViewController(in: rootViewController)
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let platformViewController = SimplePlatformViewPlugin.platformController;
        switch call.method {
        case "create":
            convertToContainerViewIfNeeded();
            platformViewController.onCreate(call, result: result)
        case "dispose":
            platformViewController.onDispose(call, result: result)
        case "acceptGesture":
            platformViewController.onAcceptGesture(call, result: result)
        case "rejectGesture":
            platformViewController.onRejectGesture(call, result: result)
        case "resize":
            platformViewController.resize(call, result: result)
        case "offset":
            platformViewController.offset(call, result: result)
        case "setBackgroundColor":
            platformViewController.setBackgroundColor(call, result: result);
        case "hotRestart":
            platformViewController.performHotRestart(call, result: result);
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Wrap the default Flutter view inside a container
    private func convertToContainerViewIfNeeded() {
        let controller = findFirstFlutterViewController();
        if (controller != nil) {
            let platformViewController = SimplePlatformViewPlugin.platformController;
            let prevView = controller!.view;
            if !(prevView is SimpleFlutterViewContainer) {
                let viewContainer = SimpleFlutterViewContainer.init(frame: CGRect.zero);
                controller!.view = viewContainer;
                controller!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                viewContainer.setFlutterView(prevView!, platformViewController);
                platformViewController.setFlutterViewContainer(viewContainer);
                platformViewController.setFlutterViewController(controller!);
            }
        }
    }
}
