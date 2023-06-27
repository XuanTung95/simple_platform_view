import UIKit
import Flutter


// This class serves as a wrapper for a real PluginRegistry and provides a convenient way to register
// a view factory into both the Flutter framework and the SimplePlatformViewPlugin.
// The class overrides the registerViewFactory() method to ensure that the view factory is properly registered
// in both environments.
@objc class FakeFlutterPluginRegistry: NSObject, FlutterPluginRegistry {
    
    private let realPluginRegistry: FlutterPluginRegistry
    private var registrars: [String: FakeFlutterPluginRegistrar] = [:];
    private var realRegistrars: [String: FlutterPluginRegistrar] = [:];
    
    init(realPluginRegistry: FlutterPluginRegistry) {
        self.realPluginRegistry = realPluginRegistry
        super.init()
    }
    
    func valuePublished(byPlugin pluginKey: String) -> NSObject? {
        return realPluginRegistry.valuePublished(byPlugin: pluginKey);
    }
    
    func registrar(forPlugin pluginKey: String) -> FlutterPluginRegistrar? {
        let realRegistrar = realPluginRegistry.registrar(forPlugin: pluginKey);
        if (realRegistrar != nil) {
            let fakeRegistrar = FakeFlutterPluginRegistrar.init(realRegistrar: realRegistrar!)
            // prevent automatic release of FlutterPluginRegistrar
            realRegistrars[pluginKey] = realRegistrar
            registrars[pluginKey] = fakeRegistrar
            return fakeRegistrar;
        }
        return nil;
    }
    
    func hasPlugin(_ pluginKey: String) -> Bool {
        return realPluginRegistry.hasPlugin(pluginKey);
    }
    
}

// This class serves as a wrapper for a real FlutterPluginRegistrar and provides a convenient way to register
// a view factory into both the Flutter framework and the SimplePlatformViewPlugin.
@objc class FakeFlutterPluginRegistrar: NSObject, FlutterPluginRegistrar {
    private let realRegistrar: FlutterPluginRegistrar
    
    init(realRegistrar: FlutterPluginRegistrar) {
        self.realRegistrar = realRegistrar
        super.init()
    }
    
    func messenger() -> FlutterBinaryMessenger {
        return realRegistrar.messenger();
    }
    
    func textures() -> FlutterTextureRegistry {
        return realRegistrar.textures();
    }
    
    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {
        realRegistrar.register(factory, withId: factoryId)
        SimplePlatformViewPlugin.registerViewFactory(factory, withId: factoryId);
    }
    
    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String, gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {
        realRegistrar.register(factory, withId: factoryId, gestureRecognizersBlockingPolicy: gestureRecognizersBlockingPolicy)
        SimplePlatformViewPlugin.registerViewFactory(factory, withId: factoryId, gestureRecognizersBlockingPolicy: gestureRecognizersBlockingPolicy);
    }
    
    func publish(_ value: NSObject) {
        realRegistrar.publish(value)
    }
    
    func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {
        realRegistrar.addMethodCallDelegate(delegate, channel: channel)
    }
    
    func addApplicationDelegate(_ delegate: FlutterPlugin) {
        realRegistrar.addApplicationDelegate(delegate);
    }
    
    func lookupKey(forAsset asset: String) -> String {
        return realRegistrar.lookupKey(forAsset: asset)
    }
    
    func lookupKey(forAsset asset: String, fromPackage package: String) -> String {
        return realRegistrar.lookupKey(forAsset: asset, fromPackage: package);
    }
}
