import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    //  let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    let factory = PipPlayerViewFactory()
    registrar(forPlugin: "pip_player_view")?.register(
      factory,
      withId: "pip_player_view"
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class PipPlayerViewFactory: NSObject, FlutterPlatformViewFactory {

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return PipPlayerView(frame: frame, viewId: viewId, args: args)
    }
}

class PipPlayerView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var player: AVPlayer

    init(frame: CGRect, viewId: Int64, args: Any?) {
        _view = UIView(frame: frame)

        let url = URL(string: "https://www.example.com/video.mp4")!
        player = AVPlayer(url: url)

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = _view.bounds
        playerLayer.videoGravity = .resizeAspect

        _view.layer.addSublayer(playerLayer)

        player.play()
    }

    func view() -> UIView {
        return _view
    }
}
