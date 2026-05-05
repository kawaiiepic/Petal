import Flutter
import UIKit
import AVFoundation

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