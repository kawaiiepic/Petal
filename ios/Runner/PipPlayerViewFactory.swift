import Flutter
import UIKit
import PipPlayerView

class PipPlayerViewFactory: NSObject, FlutterPlatformViewFactory {

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return PipPlayerView(frame: frame, viewId: viewId, args: args)
    }
}