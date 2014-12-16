//
//  ECSlidingAnimationController.swift
//  ECSwiftSlidingViewController
//
//  Created by Mihael Isaev on 15.12.14.
//

import Foundation
import UIKit

typealias ECSlidingCoordinatorAnimations = ((UIViewControllerTransitionCoordinatorContext!) -> Void)
typealias ECSlidingCoordinatorCompletion = ((UIViewControllerTransitionCoordinatorContext!) -> Void)

class ECSlidingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var coordinatorAnimations: ECSlidingCoordinatorAnimations?
    var coordinatorCompletion: ECSlidingCoordinatorCompletion?
    
    var defaultTransitionDuration: NSTimeInterval?
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        if let def = self.defaultTransitionDuration {
            return def
        } else {
            return 0.25
        }
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let topViewController = transitionContext.viewControllerForKey(ECTransitionContextTopViewControllerKey) {
            if let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {
                let containerView = transitionContext.containerView()
                let topViewInitialFrame = transitionContext.initialFrameForViewController(topViewController)
                let topViewFinalFrame = transitionContext.finalFrameForViewController(topViewController)
                
                topViewController.view.frame = topViewInitialFrame
                
                if topViewController != toViewController {
                    var toViewFinalFrame = transitionContext.finalFrameForViewController(toViewController)
                    toViewController.view.frame = toViewFinalFrame
                    containerView.insertSubview(toViewController.view, belowSubview: topViewController.view)
                }
                
                let duration = self.transitionDuration(transitionContext)
                UIView.animateWithDuration(duration, animations: { () -> Void in
                    UIView.setAnimationCurve(UIViewAnimationCurve.Linear)
                    if let coordinatorAnimations = self.coordinatorAnimations {
                        coordinatorAnimations(transitionContext as? UIViewControllerTransitionCoordinatorContext)
                    }
                    topViewController.view.frame = topViewFinalFrame
                    }) { (finished: Bool) -> Void in
                        if transitionContext.transitionWasCancelled() {
                            topViewController.view.frame = transitionContext.initialFrameForViewController(topViewController)
                        }
                        if let coordinatorCompletion = self.coordinatorCompletion {
                            coordinatorCompletion(transitionContext as? UIViewControllerTransitionCoordinatorContext)
                        }
                        transitionContext.completeTransition(finished)
                }
            }
        }
    }
}