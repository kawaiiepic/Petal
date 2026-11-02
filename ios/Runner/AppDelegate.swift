import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "petal/storage", binaryMessenger: controller.binaryMessenger).setMethodCallHandler { call, result in
        guard call.method == "freeBytes" else { result(FlutterMethodNotImplemented); return }
        let args = call.arguments as? [String: Any]
        let path = args?["path"] as? String ?? NSHomeDirectory()
        do {
          let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
          result((attributes[.systemFreeSize] as? NSNumber)?.int64Value)
        } catch { result(FlutterError(code: "storage", message: error.localizedDescription, details: nil)) }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
