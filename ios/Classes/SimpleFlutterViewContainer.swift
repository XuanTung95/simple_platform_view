import Flutter;
import UIKit

// Contain Flutter view and platform views
class SimpleFlutterViewContainer: UIView {
    private var flutterViewWapper: SimpleFlutterViewWapper?;
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func setFlutterView(_ flutterView: UIView,_ platformViewsController: SimpleFlutterPlatformViewsController) {
        let wrapper = SimpleFlutterViewWapper.init(frame: self.bounds);
        self.addSubview(wrapper);
        wrapper.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapper.setFlutterView(flutterView, platformViewsController)
        self.flutterViewWapper = wrapper;
    }
    
    public func addNewPlatformView(_ view: UIView) {
        self.insertSubview(view, at: 0)
    }
    
}

// Wrap a Flutter view and apply touch interceptor
class SimpleFlutterViewWapper: UIView {
    var flutterView: UIView?
    var platformViewsController: SimpleFlutterPlatformViewsController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func setFlutterView(_ flutterView: UIView,_ platformViewsController: SimpleFlutterPlatformViewsController) {
        self.platformViewsController = platformViewsController
        flutterView.frame = self.bounds
        flutterView.backgroundColor = .clear
        self.addSubview(flutterView);
        flutterView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.flutterView = flutterView;
    }
    
    // Pass touch event through Flutter view into platform view
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if (platformViewsController?.rootViews != nil) {
            for (_, rootView) in platformViewsController!.rootViews {
                if rootView.frame.contains(point) {
                    return false
                }
            }
        }
        return true;
    }
}
