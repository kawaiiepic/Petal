import Flutter
import UIKit

class PipPlayerViewFactory: NSObject, FlutterPlatformViewFactory {

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return PipPlayerView(frame: frame, viewId: viewId, args: args)
    }
}