import UIKit
import Flutter
import GoogleMaps
import simple_platform_view;

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("")
        let fakeRegistry = SimplePlatformViewPlugin.createFakeFlutterPluginRegistry(realPluginRegistry: self);
        GeneratedPluginRegistrant.register(with: fakeRegistry);
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
