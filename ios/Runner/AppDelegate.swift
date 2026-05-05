import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
     let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    let factory = PipPlayerViewFactory()
    registrar(forPlugin: "pip_player_view")?.register(
      factory,
      withId: "pip_player_view"
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
