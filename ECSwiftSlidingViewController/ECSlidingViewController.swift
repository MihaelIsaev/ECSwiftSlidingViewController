//
//  ECSlidingViewController.swift
//  ECSwiftSlidingViewController
//
//  Created by Mihael Isaev on 15.12.14.
//

import Foundation
import UIKit

typealias ECSlidingAnimationComplete = () -> ()

protocol ECSlidingViewControllerLayout {
    func slidingViewController(slidingViewController:ECSlidingViewController, frameForViewController viewController:UIViewController, topViewPosition:ECSlidingViewControllerTopViewPosition) -> CGRect
}

protocol ECSlidingViewControllerDelegate {
    func slidingViewController(slidingViewController:ECSlidingViewController, animationControllerForOperation operation:ECSlidingViewControllerOperation, topViewController:UIViewController) -> UIViewControllerAnimatedTransitioning
    func slidingViewController(slidingViewController:ECSlidingViewController, interactionControllerForAnimationController animationController:UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning
    func slidingViewController(slidingViewController:ECSlidingViewController, layoutControllerForTopViewPosition topViewPosition:ECSlidingViewControllerTopViewPosition) -> ECSlidingViewControllerLayout
}

protocol ECSlidingViewControllerDelegate2 {
    func slidingViewControllerDidAppear(slidingViewController:ECSlidingViewController)
    func slidingViewControllerDidDisappear(slidingViewController:ECSlidingViewController)
}

var _ECSlidingViewControllerSharedInstance: ECSlidingViewController?

class ECSlidingViewController: UIViewController, UIViewControllerContextTransitioning, UIViewControllerTransitionCoordinator, UIViewControllerTransitionCoordinatorContext {
   
    //Enable or disable the Pan gesture, without removing it
    var panGestureEnable = true
    
   var anchorLeftPeekAmount: CGFloat = 44
    /*lazy var anchorLeftPeekAmount: CGFloat = {
        if self.anchorLeftPeekAmount == CGFloat.max && self.anchorLeftRevealAmount != CGFloat.max {
            return CGRectGetWidth(self.view.bounds) - self.anchorLeftRevealAmount
        } else if self.anchorLeftPeekAmount != CGFloat.max && self.anchorLeftRevealAmount == CGFloat.max {
            return self.anchorLeftPeekAmount
        } else {
            return CGFloat.max
        }
        }()*/
   
   var anchorLeftRevealAmount: CGFloat = 276
   
    /*lazy var anchorLeftRevealAmount: CGFloat = {
        if self.anchorLeftRevealAmount == CGFloat.max && self.anchorLeftRevealAmount != CGFloat.max {
            return CGRectGetWidth(self.view.bounds) - self.anchorLeftRevealAmount
        } else if self.anchorLeftRevealAmount != CGFloat.max && self.anchorLeftRevealAmount == CGFloat.max {
            return self.anchorLeftRevealAmount
        } else {
            return CGFloat.max
        }
        }()*/
    var anchorRightPeekAmount: CGFloat = 44
    /*lazy var anchorRightPeekAmount: CGFloat = {
        if self.anchorRightPeekAmount == CGFloat.max && self.anchorRightPeekAmount != CGFloat.max {
            return CGRectGetWidth(self.view.bounds) - self.anchorRightPeekAmount
        } else if self.anchorRightPeekAmount != CGFloat.max && self.anchorRightPeekAmount == CGFloat.max {
            return self.anchorRightPeekAmount
        } else {
            return CGFloat.max
        }
        }()*/
    var anchorRightRevealAmount: CGFloat = 276
    /*lazy var anchorRightRevealAmount: CGFloat = {
        if self.anchorRightRevealAmount == CGFloat.max && self.anchorRightRevealAmount != CGFloat.max {
            return CGRectGetWidth(self.view.bounds) - self.anchorRightRevealAmount
        } else if self.anchorRightRevealAmount != CGFloat.max && self.anchorRightRevealAmount == CGFloat.max {
            return self.anchorRightRevealAmount
        } else {
            return CGFloat.max
        }
        }()*/
    
    lazy var panGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: "detectPanGestureRecognizer:")
        }()
    
    lazy var resetTapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: "resetTopViewAnimatedRecognizer:")
        }()
   
    var delegate: ECSlidingViewControllerDelegate?
    var delegate2: ECSlidingViewControllerDelegate2?
   
    var topViewController: UIViewController?
    var underLeftViewController: UIViewController?
    var underRightViewController: UIViewController?
    
    var topViewControllerStoryboardId: String?
    var underLeftViewControllerStoryboardId: String?
    var underRightViewControllerStoryboardId: String?
    
    var currentTopViewPosition: ECSlidingViewControllerTopViewPosition = .Centered
    var currentOperation: ECSlidingViewControllerOperation = .None
    var topViewAnchoredGesture = ECSlidingViewControllerAnchoredGesture.None
    
    lazy var defaultAnimationController: ECSlidingAnimationController = {
        return ECSlidingAnimationController()
        }()
    
    lazy var defaultInteractiveTransition: ECSlidingInteractiveTransition = {
        var defaultInteractiveTransition = ECSlidingInteractiveTransition(slidingViewController: self)
        defaultInteractiveTransition.animationController = self.defaultAnimationController
        return defaultInteractiveTransition;
        }()
    
    var currentAnimationController: UIViewControllerAnimatedTransitioning?
    var currentInteractiveTransition: UIViewControllerInteractiveTransitioning?
    
    lazy var gestureView: UIView = {
        return UIView(frame: CGRectZero)
        }()
    
    lazy var customAnchoredGesturesViewMap: NSMapTable = {
        return NSMapTable(keyOptions: NSMapTableWeakMemory, valueOptions: NSMapTableWeakMemory)
        }()
   
    var customAnchoredGestures: [UIGestureRecognizer] = []
    
    var currentAnimationPercentage: CGFloat = 0
    var preserveLeftPeekAmount = false
    var preserveRightPeekAmount = false
    var animated = false
    var interactive = false
    var transitionWasCancelledK = false
    var transitionInProgress = false
    
    var animationComplete: ECSlidingAnimationComplete?
    var coordinatorAnimations: ECSlidingCoordinatorAnimations?
    var coordinatorCompletion: ECSlidingCoordinatorCompletion?
    var coordinatorInteractionEnded: ECSlidingCoordinatorInteractionEnded?
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        NSNotificationCenter.defaultCenter().postNotificationName("rotateDevice", object: NSNumber(integer: toInterfaceOrientation.rawValue))
    }
    
    //MARK: - Orientation
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    //MARK: - Constructors
    
    class func slidingWithTopViewController(topViewController: UIViewController) -> ECSlidingViewController {
        return ECSlidingViewController(topViewController: topViewController)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
      _ECSlidingViewControllerSharedInstance = self
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
      super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
      _ECSlidingViewControllerSharedInstance = self
    }
    
    init(topViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
      self.topViewController = topViewController
      _ECSlidingViewControllerSharedInstance = self
    }
    
    //MARK: - UIViewController
    
    override func awakeFromNib() {
        if let topViewControllerStoryboardId = self.topViewControllerStoryboardId {
            self.topViewController = self.storyboard?.instantiateViewControllerWithIdentifier(topViewControllerStoryboardId) as? UIViewController
        }
        
        if let underLeftViewControllerStoryboardId = self.underLeftViewControllerStoryboardId {
            self.underLeftViewController = self.storyboard?.instantiateViewControllerWithIdentifier(underLeftViewControllerStoryboardId) as? UIViewController
        }
        
        if let underRightViewControllerStoryboardId = self.underRightViewControllerStoryboardId {
            self.underRightViewController = self.storyboard?.instantiateViewControllerWithIdentifier(underRightViewControllerStoryboardId) as? UIViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        anchorRightRevealAmount = self.view.frame.width - 55
        
        if let topVC = self.topViewController {
            topVC.view.frame = self.topViewCalculatedFrameForPosition(self.currentTopViewPosition)
            println("topVC.view.frame \(topVC.view.frame)")
            self.view.addSubview(topVC.view)
        } else {
            NSException(name: "Missing topViewController", reason: "Set the topViewController before loading ECSlidingViewController", userInfo: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.topViewController?.beginAppearanceTransition(true, animated:animated)
        
        if self.currentTopViewPosition == .AnchoredLeft {
            self.underRightViewController?.beginAppearanceTransition(true, animated:animated)
        } else if self.currentTopViewPosition == .AnchoredRight {
            self.underLeftViewController?.beginAppearanceTransition(true, animated:animated)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.topViewController?.endAppearanceTransition()
        
        if self.currentTopViewPosition == .AnchoredLeft {
            self.underRightViewController?.endAppearanceTransition()
        } else if self.currentTopViewPosition == .AnchoredRight {
            self.underLeftViewController?.endAppearanceTransition()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.topViewController?.beginAppearanceTransition(false, animated:animated)
        
        if self.currentTopViewPosition == .AnchoredLeft {
            self.underRightViewController?.beginAppearanceTransition(false, animated:animated)
        } else if self.currentTopViewPosition == .AnchoredRight {
            self.underLeftViewController?.beginAppearanceTransition(false, animated:animated)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.topViewController?.endAppearanceTransition()
        
        if self.currentTopViewPosition == .AnchoredLeft {
            self.underRightViewController?.endAppearanceTransition()
        } else if self.currentTopViewPosition == .AnchoredRight {
            self.underLeftViewController?.endAppearanceTransition()
        }
    }
    
    override func viewDidLayoutSubviews() {
        if self.currentOperation == .None {
            self.gestureView.frame = self.topViewCalculatedFrameForPosition(self.currentTopViewPosition)
            self.topViewController?.view.frame = self.topViewCalculatedFrameForPosition(self.currentTopViewPosition)
            self.underLeftViewController?.view.frame = self.underLeftViewCalculatedFrameForTopViewPosition(self.currentTopViewPosition)
            self.underRightViewController?.view.frame = self.underRightViewCalculatedFrameForTopViewPosition(self.currentTopViewPosition)
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return self.currentOperation == .None
    }
    
    override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
        return false
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        if object_getClass(self.underLeftViewController!) === object_getClass(toViewController) || object_getClass(self.underRightViewController) === object_getClass(toViewController) {
            let unwindSegue = ECSlidingSegue(identifier: identifier, source: fromViewController, destination: toViewController)
            unwindSegue.setValue(true, forKey:"isUnwinding")
            return unwindSegue;
        } else {
            return super.segueForUnwindingToViewController(toViewController, fromViewController:fromViewController, identifier:identifier)
        }
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        if self.currentTopViewPosition == .Centered {
            return self.topViewController;
        } else if self.currentTopViewPosition == .AnchoredLeft {
            return self.underRightViewController;
        } else if self.currentTopViewPosition == .AnchoredRight {
            return self.underLeftViewController;
        } else {
            return nil;
        }
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        if self.currentTopViewPosition == .Centered {
            return self.topViewController;
        } else if self.currentTopViewPosition == .AnchoredLeft {
            return self.underRightViewController;
        } else if self.currentTopViewPosition == .AnchoredRight {
            return self.underLeftViewController;
        } else {
            return nil;
        }
    }
    
    override func transitionCoordinator() -> UIViewControllerTransitionCoordinator? {
        if !self.transitionInProgress {
            return super.transitionCoordinator()
        }
        return self
    }
    
    //MARK: - Properties
    
    func setTopViewControllerWithStoryboardID(sbID: String) {
        self.setTopViewController(self.storyboard!.instantiateViewControllerWithIdentifier(sbID) as UIViewController)
    }
    
    func setTopViewController(topViewController: UIViewController) {
        if let oldTopViewController = self.topViewController {
            oldTopViewController.view.removeFromSuperview()
            oldTopViewController.willMoveToParentViewController(nil)
            oldTopViewController.beginAppearanceTransition(false, animated:false)
            oldTopViewController.removeFromParentViewController()
            oldTopViewController.endAppearanceTransition()
        }
       
        self.topViewController = topViewController
        
        if let topVC = self.topViewController {
            self.addChildViewController(topVC)
            topVC.didMoveToParentViewController(self)
            
            if self.isViewLoaded() {
                topVC.beginAppearanceTransition(true, animated:false)
                self.view.addSubview(topVC.view)
                topVC.endAppearanceTransition()
            }
        }
    }
    
    func setUnderLeftViewController(underLeftViewController: UIViewController) {
        if let oldUnderLeftViewController = self.underLeftViewController {
            oldUnderLeftViewController.view.removeFromSuperview()
            oldUnderLeftViewController.willMoveToParentViewController(nil)
            oldUnderLeftViewController.beginAppearanceTransition(false, animated:false)
            oldUnderLeftViewController.removeFromParentViewController()
            oldUnderLeftViewController.endAppearanceTransition()
        }
        
        self.underLeftViewController = underLeftViewController
        
        if let underLeftVC = self.underLeftViewController {
            self.addChildViewController(underLeftVC)
            underLeftVC.didMoveToParentViewController(self)
        }
    }
    
    func setUnderRightViewController(underRightViewController: UIViewController) {
        if let oldUnderRightViewController = self.underRightViewController {
            oldUnderRightViewController.view.removeFromSuperview()
            oldUnderRightViewController.willMoveToParentViewController(nil)
            oldUnderRightViewController.beginAppearanceTransition(false, animated:false)
            oldUnderRightViewController.removeFromParentViewController()
            oldUnderRightViewController.endAppearanceTransition()
        }
        
        self.underRightViewController = underRightViewController
        
        if let underRightVC = self.underRightViewController {
            self.addChildViewController(underRightVC)
            underRightVC.didMoveToParentViewController(self)
        }
    }
    
    func setAnchorLeftPeekAmount(anchorLeftPeekAmount: CGFloat) {
        self.anchorLeftPeekAmount   = anchorLeftPeekAmount
        self.anchorLeftRevealAmount = CGFloat.max
        self.preserveLeftPeekAmount = true
    }
    
    func setAnchorLeftRevealAmount(anchorLeftRevealAmount: CGFloat) {
        self.anchorLeftRevealAmount = anchorLeftRevealAmount
        self.anchorLeftPeekAmount   = CGFloat.max
        self.preserveLeftPeekAmount = false
    }
    
    func setAnchorRightPeekAmount(anchorRightPeekAmount: CGFloat) {
        self.anchorRightPeekAmount   = anchorRightPeekAmount
        self.anchorRightRevealAmount = CGFloat.max
        self.preserveRightPeekAmount = true
    }
    
    func setAnchorRightRevealAmount(anchorRightRevealAmount: CGFloat) {
        self.anchorRightRevealAmount = anchorRightRevealAmount
        self.anchorRightPeekAmount   = CGFloat.max
        self.preserveRightPeekAmount = false
    }
    
    func setDefaultTransitionDuration(defaultTransitionDuration: NSTimeInterval) {
        self.defaultAnimationController.defaultTransitionDuration = defaultTransitionDuration
    }
    
    //MARK: - Public
    
    func anchorTopViewToRightAnimated(animated: Bool, onComplete: ECSlidingAnimationComplete? = nil) {
        self.moveTopViewToPosition(.AnchoredRight, animated:animated, onComplete:onComplete)
    }
    
    func anchorTopViewToLeftAnimated(animated: Bool, onComplete: ECSlidingAnimationComplete? = nil) {
        self.moveTopViewToPosition(.AnchoredLeft, animated:animated, onComplete:onComplete)
    }
    
    func resetTopViewAnimated(animated: Bool, onComplete: ECSlidingAnimationComplete? = nil) {
        self.moveTopViewToPosition(.Centered, animated:animated, onComplete:onComplete)
    }
    
    //MARK: - Private
    
    func moveTopViewToPosition(position: ECSlidingViewControllerTopViewPosition, animated: Bool, onComplete: ECSlidingAnimationComplete? = nil) {
        self.animated = animated
        self.animationComplete = onComplete
        self.view.endEditing(true)
        let operation = self.operationFromPosition(self.currentTopViewPosition, toPosition:position)
        self.animateOperation(operation)
    }
    
    func topViewCalculatedFrameForPosition(position: ECSlidingViewControllerTopViewPosition) -> CGRect {
        let frameFromDelegate = self.frameFromDelegateForViewController(self.topViewController!, topViewPosition: position)

        if !CGRectIsInfinite(frameFromDelegate) {
           return frameFromDelegate
        }
      
        var containerViewFrame = self.view.bounds
      
        if (!((self.topViewController!.edgesForExtendedLayout & UIRectEdge.Top) == UIRectEdge.Top)) {
           var topLayoutGuideLength = self.topLayoutGuide.length
           containerViewFrame.origin.y     = topLayoutGuideLength
           containerViewFrame.size.height -= topLayoutGuideLength
        }
      
        if (!((self.topViewController!.edgesForExtendedLayout & UIRectEdge.Bottom) == UIRectEdge.Bottom)) {
           var bottomLayoutGuideLength = self.bottomLayoutGuide.length
           containerViewFrame.size.height -= bottomLayoutGuideLength
        }
      
        switch position {
            case .Centered:
                return containerViewFrame
            case .AnchoredLeft:
                containerViewFrame.origin.x = -self.anchorLeftRevealAmount
                return containerViewFrame
            case .AnchoredRight:
                containerViewFrame.origin.x = self.anchorRightRevealAmount
                return containerViewFrame
            default:
                return CGRectZero
         }
    }
   
    func underLeftViewCalculatedFrameForTopViewPosition(position: ECSlidingViewControllerTopViewPosition) -> CGRect {
        var frameFromDelegate = self.frameFromDelegateForViewController(self.underLeftViewController!, topViewPosition: position)
        if !CGRectIsInfinite(frameFromDelegate){
            return frameFromDelegate
        }
        
        var containerViewFrame = self.view.bounds
        
        var topLayoutGuideLength = self.topLayoutGuide.length
        containerViewFrame.origin.y = topLayoutGuideLength
        containerViewFrame.size.height -= topLayoutGuideLength
        
        var bottomLayoutGuideLength = self.bottomLayoutGuide.length
        containerViewFrame.size.height -= bottomLayoutGuideLength
        
        containerViewFrame.size.width = self.anchorRightRevealAmount
        
        return containerViewFrame
    }
   
    func underRightViewCalculatedFrameForTopViewPosition(position: ECSlidingViewControllerTopViewPosition) -> CGRect {
      var frameFromDelegate = self.frameFromDelegateForViewController(self.underRightViewController, topViewPosition: position)
      if !CGRectIsInfinite(frameFromDelegate){
         return frameFromDelegate
      }
      
      var containerViewFrame = self.view.bounds
      
      if let underRightViewController = self.underRightViewController {
        var topLayoutGuideLength = self.topLayoutGuide.length
        containerViewFrame.origin.y = topLayoutGuideLength
        containerViewFrame.size.height -= topLayoutGuideLength
        
        var bottomLayoutGuideLength = self.bottomLayoutGuide.length
        containerViewFrame.size.height -= bottomLayoutGuideLength
        
        containerViewFrame.origin.x   = self.anchorLeftPeekAmount
        containerViewFrame.size.width = self.anchorLeftRevealAmount
        
      }
      
      return containerViewFrame
    }
   
    func frameFromDelegateForViewController(viewController: UIViewController?, topViewPosition: ECSlidingViewControllerTopViewPosition) -> CGRect {
      var frame = CGRectInfinite
      
      if let vc = viewController {
         if let layoutController = self.delegate?.slidingViewController(self, layoutControllerForTopViewPosition: topViewPosition) {
            frame = layoutController.slidingViewController(self, frameForViewController: vc, topViewPosition: topViewPosition)
         }
      }
      
      return frame
    }
   
    func operationFromPosition(fromPosition: ECSlidingViewControllerTopViewPosition, toPosition: ECSlidingViewControllerTopViewPosition) -> ECSlidingViewControllerOperation {
        if fromPosition == .Centered && toPosition == .AnchoredLeft {
            return .AnchorLeft
        } else if fromPosition == .Centered && toPosition == .AnchoredRight {
            return .AnchorRight
        } else if fromPosition == .AnchoredLeft && toPosition == .Centered {
            return .ResetFromLeft
        } else if fromPosition == .AnchoredRight && toPosition == .Centered {
            return .ResetFromRight
        } else {
            return .None
        }
    }
    
    func animateOperation(operation: ECSlidingViewControllerOperation) {
      if !self.operationIsValid(operation) {
         self.interactive = false
         return
      }
      if self.transitionInProgress {
         return
      }
      
      self.view.userInteractionEnabled = false
      
      self.transitionInProgress = true
      
      self.currentOperation = operation
      
      if let currentAnimationController = self.delegate?.slidingViewController(self, animationControllerForOperation: operation, topViewController: self.topViewController!) {
         self.currentAnimationController = currentAnimationController
         if let currentInteractiveTransition = self.delegate?.slidingViewController(self, interactionControllerForAnimationController: currentAnimationController) {
            self.currentInteractiveTransition = currentInteractiveTransition
         } else {
            self.currentInteractiveTransition = nil
         }
      } else {
         self.currentAnimationController = nil
      }
      
      if let currentAnimationController = self.currentAnimationController {
         if let currentInteractiveTransition = self.currentInteractiveTransition {
            self.interactive = true
         } else {
            self.defaultInteractiveTransition.animationController = self.currentAnimationController
            self.currentInteractiveTransition = self.defaultInteractiveTransition
         }
      } else {
         self.currentAnimationController = self.defaultAnimationController;
         
         self.defaultInteractiveTransition.animationController = self.currentAnimationController
         self.currentInteractiveTransition = self.defaultInteractiveTransition
      }
      
      self.beginAppearanceTransitionForOperation(operation)
      
      self.defaultAnimationController.coordinatorAnimations = self.coordinatorAnimations
      self.defaultAnimationController.coordinatorCompletion = self.coordinatorCompletion
      self.defaultInteractiveTransition.coordinatorInteractionEnded = self.coordinatorInteractionEnded
      
      if self.isInteractive() {
         self.currentInteractiveTransition!.startInteractiveTransition(self)
      } else {
         self.currentAnimationController!.animateTransition(self)
      }
    }
   
    func operationIsValid(operation: ECSlidingViewControllerOperation) -> Bool {
        if self.currentTopViewPosition == .AnchoredLeft {
            if operation == .ResetFromLeft {
                return true
            }
        } else if self.currentTopViewPosition == .AnchoredRight {
            if operation == .ResetFromRight {
                return true
            }
        } else if self.currentTopViewPosition == .Centered {
            if operation == .AnchorLeft {
                return self.underRightViewController != nil
            } else if operation == .AnchorRight {
                return self.underLeftViewController != nil
            }
        }
        return false
    }
    
    func beginAppearanceTransitionForOperation(operation: ECSlidingViewControllerOperation) {
        let viewControllerWillAppear    = self.viewControllerWillAppearForSuccessfulOperation(operation)
        let viewControllerWillDisappear = self.viewControllerWillDisappearForSuccessfulOperation(operation)
        
        viewControllerWillAppear.beginAppearanceTransition(true, animated:self.isAnimated())
        viewControllerWillDisappear.beginAppearanceTransition(false, animated:self.isAnimated())
    }
    
    func endAppearanceTransitionForOperation(operation: ECSlidingViewControllerOperation, isCancelled canceled: Bool) {
        let viewControllerWillAppear    = self.viewControllerWillAppearForSuccessfulOperation(operation)
        let viewControllerWillDisappear = self.viewControllerWillDisappearForSuccessfulOperation(operation)
        
        if canceled {
            viewControllerWillDisappear.beginAppearanceTransition(true, animated:self.isAnimated())
            viewControllerWillDisappear.endAppearanceTransition()
            viewControllerWillAppear.beginAppearanceTransition(false, animated:self.isAnimated())
            viewControllerWillAppear.endAppearanceTransition()
        } else {
            viewControllerWillDisappear.endAppearanceTransition()
            viewControllerWillAppear.endAppearanceTransition()
            
            if operation == .AnchorLeft || operation == .AnchorRight {
                self.delegate2?.slidingViewControllerDidAppear(self)
            }else if operation == .ResetFromLeft || operation == .ResetFromRight {
                self.delegate2?.slidingViewControllerDidDisappear(self)
            }
        }
    }
    
    func viewControllerWillAppearForSuccessfulOperation(operation: ECSlidingViewControllerOperation) -> UIViewController {
        var viewControllerWillAppear = UIViewController()
        
        if operation == .AnchorLeft {
            if let underRightViewController = self.underRightViewController {
                viewControllerWillAppear = underRightViewController
            }
        } else if operation == .AnchorRight {
            if let underLeftViewController = self.underLeftViewController {
                //Call when leftViewController will appear & when it appears
                viewControllerWillAppear = underLeftViewController
            }
        }
        
        return viewControllerWillAppear
    }
    
    func viewControllerWillDisappearForSuccessfulOperation(operation: ECSlidingViewControllerOperation) -> UIViewController {
        var viewControllerWillDisappear = UIViewController()
        
        if operation == .ResetFromLeft {
            if let underRightViewController = self.underRightViewController {
                viewControllerWillDisappear = underRightViewController
            }
        } else if operation == .ResetFromRight {
            if let underLeftViewController = self.underLeftViewController {
                viewControllerWillDisappear = underLeftViewController
            }
        }
        
        return viewControllerWillDisappear
    }
    
    func updateTopViewGestures() {
      var topViewIsAnchored = self.currentTopViewPosition == .AnchoredLeft || self.currentTopViewPosition == .AnchoredRight
      var topView = self.topViewController!.view
      
      if topViewIsAnchored {
         if self.topViewAnchoredGesture == .Disabled {
            topView.userInteractionEnabled = false
         } else {
            self.gestureView.frame = topView.frame;
            
            var foundedPanGesture = false
            if let pp: AnyObject = self.customAnchoredGesturesViewMap.objectForKey(self.panGesture) {
               foundedPanGesture = true
            }
            
            if self.topViewAnchoredGesture == .Panning && !foundedPanGesture {
               self.customAnchoredGesturesViewMap.setObject(self.panGesture.view!, forKey:self.panGesture)
               self.panGesture.view!.removeGestureRecognizer(self.panGesture)
               self.gestureView.addGestureRecognizer(self.panGesture)
               if let superview = self.gestureView.superview {
                  
               } else {
                  self.view.insertSubview(self.gestureView, aboveSubview:topView)
               }
            }
            
            var foundedTapGesture = false
            if let pp: AnyObject = self.customAnchoredGesturesViewMap.objectForKey(self.resetTapGesture) {
               foundedTapGesture = true
            }
            
            if self.topViewAnchoredGesture == .Tapping && !foundedTapGesture {
               self.gestureView.addGestureRecognizer(self.resetTapGesture)
               if let superview = self.gestureView.superview {
                  
               } else {
                  self.view.insertSubview(self.gestureView, aboveSubview:topView)
               }
            }
            if self.topViewAnchoredGesture == .Custom {
               for gesture in self.customAnchoredGestures {
                  if let gesture: AnyObject = self.customAnchoredGesturesViewMap.objectForKey(gesture) {
                     
                  } else {
                     self.customAnchoredGesturesViewMap.setObject(gesture.view!, forKey:gesture)
                     gesture.view!.removeGestureRecognizer(gesture)
                     self.gestureView.addGestureRecognizer(gesture)
                  }
               }
               if let superview = self.gestureView.superview {
                  
               } else {
                  self.view.insertSubview(self.gestureView, aboveSubview:topView)
               }
            }
         }
      } else {
         self.topViewController!.view.userInteractionEnabled = true
         self.gestureView.removeFromSuperview()
         for gesture in self.customAnchoredGestures {
            var originalView = self.customAnchoredGesturesViewMap.objectForKey(gesture)! as UIView
            if originalView.isDescendantOfView(self.topViewController!.view) {
               originalView.addGestureRecognizer(gesture)
            }
         }
         if let panGesture = self.customAnchoredGesturesViewMap.objectForKey(self.panGesture) as? UIView {
            if view.isDescendantOfView(self.topViewController!.view) {
               view.addGestureRecognizer(self.panGesture)
            }
         }
         self.customAnchoredGesturesViewMap.removeAllObjects()
      }
    }
    
    //MARK: - UIPanGestureRecognizer action
    
    func detectPanGestureRecognizer(recognizer: UIPanGestureRecognizer) {
        if panGestureEnable {
            if recognizer.state == .Began {
                self.view.endEditing(true)
                self.interactive = true
            }
            
            self.defaultInteractiveTransition.updateTopViewHorizontalCenterWithRecognizer(recognizer)
            self.interactive = false
        }
    }
    
    
    //MARK: - UITapGestureRecognizer action
    
    func resetTopViewAnimatedRecognizer( recognizer: UITapGestureRecognizer) {
        self.resetTopViewAnimated(true, onComplete: nil)
    }
    
    //MARK: - UIViewControllerTransitionCoordinatorContext
    
    func initiallyInteractive() -> Bool {
        return self.isAnimated() && self.isInteractive()
    }
    
    func isCancelled() -> Bool {
        return self.transitionWasCancelled()
    }
    
    func transitionDuration() -> NSTimeInterval {
        return self.currentAnimationController!.transitionDuration(self)
    }
    
    func percentComplete() -> CGFloat {
        return self.currentAnimationPercentage
    }
    
    func completionVelocity() -> CGFloat {
        return 1
    }
    
    func completionCurve() -> UIViewAnimationCurve {
        return .Linear
    }
    
    //MARK: - UIViewControllerContextTransitioning and UIViewControllerTransitionCoordinatorContext
    
    func containerView() -> UIView {
        return self.view
    }
   
    func isAnimated() -> Bool {
        return self.animated
    }
   
    func isInteractive() -> Bool {
       return self.interactive
    }
   
    func transitionWasCancelled() -> Bool {
       return self.transitionWasCancelledK
    }
    
    func presentationStyle() -> UIModalPresentationStyle {
        return .Custom
    }
    
    func updateInteractiveTransition(percentComplete: CGFloat) {
        self.currentAnimationPercentage = percentComplete
    }
    
    func finishInteractiveTransition() {
        self.transitionWasCancelledK = false
    }
    
    func cancelInteractiveTransition() {
        self.transitionWasCancelledK = true
    }
    
    func completeTransition(didComplete: Bool) {
        if self.currentOperation == .None {
            return
        }
        
        if self.transitionWasCancelled() {
            if self.currentOperation == .AnchorLeft {
                self.currentTopViewPosition = .Centered
            } else if self.currentOperation == .AnchorRight {
                self.currentTopViewPosition = .Centered
            } else if self.currentOperation == .ResetFromLeft {
                self.currentTopViewPosition = .AnchoredLeft
            } else if self.currentOperation == .ResetFromRight {
                self.currentTopViewPosition = .AnchoredRight
            }
        } else {
            if (self.currentOperation == .AnchorLeft) {
                self.currentTopViewPosition = .AnchoredLeft
            } else if self.currentOperation == .AnchorRight {
                self.currentTopViewPosition = .AnchoredRight
            } else if self.currentOperation == .ResetFromLeft {
                self.currentTopViewPosition = .Centered
            } else if self.currentOperation == .ResetFromRight {
                self.currentTopViewPosition = .Centered
            }
        }
        
        if let animationEnded = self.currentAnimationController?.animationEnded {
            animationEnded(didComplete)
        }
        
        if let animationComplete = self.animationComplete {
            animationComplete()
        }
        
        self.animationComplete = nil
        
        self.updateTopViewGestures()
        self.endAppearanceTransitionForOperation(self.currentOperation, isCancelled:self.transitionWasCancelled())
        
        self.transitionWasCancelledK     = false
        self.interactive                 = false
        self.coordinatorAnimations       = nil
        self.coordinatorCompletion       = nil
        self.coordinatorInteractionEnded = nil
        self.currentAnimationPercentage  = 0
        self.currentOperation            = .None
        self.transitionInProgress        = false
        self.view.userInteractionEnabled = true
        UIViewController.attemptRotationToDeviceOrientation()
        self.setNeedsStatusBarAppearanceUpdate()
    }
   
   func viewForKey(key: String) -> UIView? {
      return UIView()
   }
   
   func targetTransform() -> CGAffineTransform {
      return CGAffineTransformMake(0, 0, 0, 0, 0, 0)
   }
   
    func viewControllerForKey(key: String) -> UIViewController? {
        if key == ECTransitionContextTopViewControllerKey {
            return self.topViewController
        } else if key == ECTransitionContextUnderLeftControllerKey {
            return self.underLeftViewController
        } else if key == ECTransitionContextUnderRightControllerKey {
            return self.underRightViewController
        }
        
        if self.currentOperation == .AnchorLeft {
            if key == UITransitionContextFromViewControllerKey {
                return self.topViewController
            }
            if key == UITransitionContextToViewControllerKey {
                return self.underRightViewController
            }
        } else if self.currentOperation == .AnchorRight {
            if key == UITransitionContextFromViewControllerKey {
                return self.topViewController
            }
            if key == UITransitionContextToViewControllerKey {
                return self.underLeftViewController
            }
        } else if self.currentOperation == .ResetFromLeft {
            if key == UITransitionContextFromViewControllerKey {
                return self.underRightViewController
            }
            if key == UITransitionContextToViewControllerKey {
                return self.topViewController
            }
        } else if self.currentOperation == .ResetFromRight {
            if key == UITransitionContextFromViewControllerKey {
                return self.underLeftViewController
            }
            if key == UITransitionContextToViewControllerKey {
                return self.topViewController
            }
        }
        
        return nil;
    }
    
    func initialFrameForViewController(vc: UIViewController) -> CGRect {
        if self.currentOperation == .AnchorLeft {
            if vc == self.topViewController {
                return self.topViewCalculatedFrameForPosition(.Centered)
            }
        } else if self.currentOperation == .AnchorRight {
            if vc == self.topViewController {
                return self.topViewCalculatedFrameForPosition(.Centered)
            }
        } else if self.currentOperation == .ResetFromLeft {
            if vc == self.topViewController{
                return self.topViewCalculatedFrameForPosition(.AnchoredLeft)
            }
            if vc == self.underRightViewController{
                return self.underRightViewCalculatedFrameForTopViewPosition(.AnchoredLeft)
            }
        } else if self.currentOperation == .ResetFromRight {
            if vc == self.topViewController{
                return self.topViewCalculatedFrameForPosition(.AnchoredRight)
            }
            if vc == self.underLeftViewController{
                return self.underLeftViewCalculatedFrameForTopViewPosition(.AnchoredRight)
            }
        }
        
        return CGRectZero
    }
    
    func finalFrameForViewController(vc: UIViewController) -> CGRect {
        if self.currentOperation == .AnchorLeft {
            if vc == self.topViewController {
                return self.topViewCalculatedFrameForPosition(.AnchoredLeft)
            }
            if vc == self.underRightViewController {
                return self.underRightViewCalculatedFrameForTopViewPosition(.AnchoredLeft)
            }
        } else if self.currentOperation == .AnchorRight {
            if vc == self.topViewController {
                return self.topViewCalculatedFrameForPosition(.AnchoredRight)
            }
            if vc == self.underLeftViewController {
                return self.underLeftViewCalculatedFrameForTopViewPosition(.AnchoredRight)
            }
        } else if self.currentOperation == .ResetFromLeft {
            if vc == self.topViewController {
                return self.topViewCalculatedFrameForPosition(.Centered)
            }
        } else if self.currentOperation == .ResetFromRight {
            if vc == self.topViewController {
                return self.topViewCalculatedFrameForPosition(.Centered)
            }
        }
        
        return CGRectZero
    }
    
    //MARK: - UIViewControllerTransitionCoordinator
   
    func animateAlongsideTransitionInView(view: UIView!, animation: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!, completion: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!) -> Bool {
        self.coordinatorAnimations = animation
        self.coordinatorCompletion = completion
        return true
    }
   
    func animateAlongsideTransition(animation: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!, completion: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!) -> Bool {
         self.coordinatorAnimations = animation
         self.coordinatorCompletion = completion
         return true
    }
    
    func notifyWhenInteractionEndsUsingBlock(handler: (UIViewControllerTransitionCoordinatorContext!) -> Void) {
        self.coordinatorInteractionEnded = handler
    }
    
    func toggleWithRightPosition() {
        if self.currentTopViewPosition == .AnchoredLeft || self.currentTopViewPosition == .AnchoredRight {
            self.resetTopViewAnimated(true)
        } else {
            self.anchorTopViewToRightAnimated(true)
        }
    }
    
    func toggleWithLeftPosition() {
        if self.currentTopViewPosition == .AnchoredLeft || self.currentTopViewPosition == .AnchoredRight {
            self.resetTopViewAnimated(true)
        } else {
            self.anchorTopViewToLeftAnimated(true)
        }
    }
}
