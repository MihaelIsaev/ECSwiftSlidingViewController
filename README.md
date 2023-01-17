ECSlidingViewController in Swift!
============================

Translated into Swift ECSlidingViewController

Hello everyone!

I rewrote [the whole library](https://github.com/ECSlidingViewController/ECSlidingViewController) into Swift.
I've fixed critical bugs, but I still need help. Now the most nasty problem is not smoothly opening menu with slide gesture..

Any help is welcome!

How it works:

```swift
let topViewController = self.storyboard?.instantiateViewControllerWithIdentifier("topView") as UIViewController

let underViewController = self.storyboard?.instantiateViewControllerWithIdentifier("leftView") as UITableViewController

slidingController = ECSlidingViewController(topViewController: topViewController)
slidingController.setUnderLeftViewController(underViewController)

self.view.addSubview(slidingController.view)
```

Now this can work with `UITabBar`, with `delegate2`

Delegate of the class
```swift
ECSlidingViewControllerDelegate2
```

add the `delegate2`
```swift
slidingController.delegate2 = self
```

Add this methods to properly work with UITabBar

```swift
// Tap gesture, to add it to the view and remove you dont need it
var resetTapGesture: UIGestureRecognizer!

var gesturesView: UIView! // Overlay view to TopViewController to prevent other taps, scrolls in other screens

override func viewDidLoad() {
    // Initalize gesturesView
    gesturesView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
}

func slidingViewControllerDidAppear(slidingViewController: ECSlidingViewController) {
    // Add gestures view to TopView
    topViewController.view.addSubview(gesturesView)

    // Add Tap Gesture, for reset
    gesturesView.addGestureRecognizer(resetTapGesture)
}
    
func slidingViewControllerDidDisappear(slidingViewController: ECSlidingViewController) {
    // Remove gestures view to TopView
    gesturesView.removeFromSuperview()

    // Remove Tap Gesture
    gesturesView.removeGestureRecognizer(resetTapGesture)
}
```

