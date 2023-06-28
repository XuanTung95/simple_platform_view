import Flutter;
import UIKit

// A UIView that is used as the parent for embedded UIViews.
//
// This view has 2 roles:
// 1. Delay or prevent touch events from arriving the embedded view.
// 2. Dispatching all events that are hittested to the embedded view to the FlutterView.
class FlutterTouchInterceptingView: UIView {
    private var delayingRecognizer: DelayingGestureRecognizer!
    private let blockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy
    private let embeddedView: UIView
    private var initFrame: CGRect;
    private var addedSubview = false;
    
    init(frame: CGRect, embeddedView: UIView, platformViewsController: SimpleFlutterPlatformViewsController, gestureRecognizersBlockingPolicy blockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {
        self.embeddedView = embeddedView
        self.initFrame = frame;
        self.blockingPolicy = blockingPolicy
        super.init(frame: CGRect.zero)
        let forwardingRecognizer = ForwardingGestureRecognizer(target: self, platformViewsController: platformViewsController)
        self.delayingRecognizer = DelayingGestureRecognizer(target: self, action: nil, forwardingRecognizer: forwardingRecognizer)
        self.isMultipleTouchEnabled = true
        
        self.addGestureRecognizer(self.delayingRecognizer)
        self.addGestureRecognizer(forwardingRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setOffset(left: Double, top: Double) {
        if (!addedSubview) {
            // add embeddedView as sub view first time setOffset is called
            addedSubview = true;
            let frame = CGRect(x: left, y: top, width: initFrame.width, height: initFrame.height);
            self.frame = frame
            embeddedView.frame = self.bounds
            self.addSubview(embeddedView)
            embeddedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        } else {
            self.frame.origin.x = left
            self.frame.origin.y = top
        }
    }
    
    public func resize(width: Double, height: Double, left: Double? = nil, top: Double? = nil) {
        if (!addedSubview) {
            self.initFrame.size.width = width
            self.initFrame.size.height = height
            if (top != nil && left != nil) {
                self.setOffset(left: left!, top: top!)
            }
        } else {
            self.frame.size.width = width
            self.frame.size.height = height
            if (top != nil && left != nil) {
                self.frame.origin.x = left!
                self.frame.origin.y = top!
            }
        }
    }
    
    func releaseGesture() {
        delayingRecognizer.state = .failed
    }
    
    func blockGesture() {
        switch blockingPolicy {
        case FlutterPlatformViewGestureRecognizersBlockingPolicyEager:
            delayingRecognizer.state = .ended
        case FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded:
            if delayingRecognizer.touchedEndedWithoutBlocking {
                delayingRecognizer.state = .ended
            } else {
                delayingRecognizer.shouldEndInNextTouchesEnded = true
            }
        default:
            break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Do nothing
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Do nothing
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Do nothing
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Do nothing
    }
}

// This recognizers delays touch events from being dispatched to the responder chain until it failed
// recognizing a gesture.
//
// We only fail this recognizer when asked to do so by the Flutter framework (which does so by
// invoking an acceptGesture method on the platform_views channel). And this is how we allow the
// Flutter framework to delay or prevent the embedded view from getting a touch sequence.
class DelayingGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    private let forwardingRecognizer: UIGestureRecognizer
    
    var shouldEndInNextTouchesEnded: Bool = false
    var touchedEndedWithoutBlocking: Bool = false
    
    init(target: Any?, action: Selector?, forwardingRecognizer: UIGestureRecognizer) {
        self.forwardingRecognizer = forwardingRecognizer
        
        super.init(target: target, action: action)
        
        self.delaysTouchesBegan = true
        self.delaysTouchesEnded = true
        self.delegate = self
        self.shouldEndInNextTouchesEnded = false
        self.touchedEndedWithoutBlocking = false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer != forwardingRecognizer && otherGestureRecognizer != self
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer == self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        touchedEndedWithoutBlocking = false
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if shouldEndInNextTouchesEnded {
            state = .ended
            shouldEndInNextTouchesEnded = false
        } else {
            touchedEndedWithoutBlocking = true
        }
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }
}

// While the DelayingGestureRecognizer is preventing touches from hitting the responder chain
// the touch events are not arriving to the FlutterView (and thus not arriving to the Flutter
// framework). We use this gesture recognizer to dispatch the events directly to the FlutterView
// while during this phase.
//
// If the Flutter framework decides to dispatch events to the embedded view, we fail the
// DelayingGestureRecognizer which sends the events up the responder chain. But since the events
// are handled by the embedded view they are not delivered to the Flutter framework in this phase
// as well. So during this phase as well the ForwardingGestureRecognizer dispatched the events
// directly to the FlutterView.
class ForwardingGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    private let platformViewsController: SimpleFlutterPlatformViewsController
    private var currentTouchPointersCount: Int = 0
    private var flutterViewController: FlutterViewController?
    
    init(target: Any?, platformViewsController: SimpleFlutterPlatformViewsController) {
        self.platformViewsController = platformViewsController
        super.init(target: target, action: nil)
        self.delegate = self
        self.currentTouchPointersCount = 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if currentTouchPointersCount == 0 {
            flutterViewController = platformViewsController.getFlutterViewController();
        }
        flutterViewController?.touchesBegan(touches, with: event)
        currentTouchPointersCount += touches.count
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        flutterViewController?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        flutterViewController?.touchesEnded(touches, with: event)
        currentTouchPointersCount -= touches.count
        if currentTouchPointersCount == 0 {
            self.state = .failed
            flutterViewController = nil
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        flutterViewController?.touchesCancelled(touches, with: event);
        currentTouchPointersCount -= touches.count
        if currentTouchPointersCount == 0 {
            state = .failed
            flutterViewController = nil
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
