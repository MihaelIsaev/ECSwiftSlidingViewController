//
//  ECSlidingInteractiveTransition.swift
//  ECSwiftSlidingViewController
//
//  Created by Mihael Isaev on 15.12.14.
//

import Foundation
import UIKit

typealias ECSlidingCoordinatorInteractionEnded = (context: ECSlidingViewController) -> ()

class ECSlidingInteractiveTransition: ECPercentDrivenInteractiveTransition {
    
    var coordinatorInteractionEnded: ECSlidingCoordinatorInteractionEnded?
    
    var slidingViewController: ECSlidingViewController!
    var positiveLeftToRight = false
    var fullWidth: CGFloat = 0
    var currentPercentage: CGFloat = 0
    
    //MARK: - Constructors
    
    init(slidingViewController: ECSlidingViewController) {
        super.init()
        self.slidingViewController = slidingViewController
    }
    
    //MARK: - UIViewControllerInteractiveTransitioning
    
    override func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
        
        if let topViewController = transitionContext.viewControllerForKey(ECTransitionContextTopViewControllerKey) {
            let finalLeftEdge = CGRectGetMinX(transitionContext.finalFrameForViewController(topViewController))
            let initialLeftEdge = CGRectGetMinX(transitionContext.initialFrameForViewController(topViewController))
            let fullWidth = fabs(finalLeftEdge - initialLeftEdge)
            self.positiveLeftToRight = initialLeftEdge < finalLeftEdge
            self.fullWidth           = fullWidth
            self.currentPercentage   = 0
        }
    }
    
    //MARK: - UIPanGestureRecognizer action
    
    func updateTopViewHorizontalCenterWithRecognizer(recognizer: UIPanGestureRecognizer) {
        var translationX = recognizer.translationInView(self.slidingViewController.view).x
        var velocityX    = recognizer.velocityInView(self.slidingViewController.view).x
        
        switch recognizer.state {
        case UIGestureRecognizerState.Began:
            let isMovingRight = velocityX > 0
            
            if self.slidingViewController.currentTopViewPosition == .Centered && isMovingRight {
                self.slidingViewController.anchorTopViewToRightAnimated(true)
            } else if self.slidingViewController.currentTopViewPosition == .Centered && !isMovingRight {
                self.slidingViewController.anchorTopViewToLeftAnimated(true)
            } else if self.slidingViewController.currentTopViewPosition == .AnchoredLeft {
                self.slidingViewController.resetTopViewAnimated(true)
            } else if self.slidingViewController.currentTopViewPosition == .AnchoredRight {
                self.slidingViewController.resetTopViewAnimated(true)
            }
            break;
        case UIGestureRecognizerState.Changed:
            if !self.positiveLeftToRight {
                translationX = translationX * -1
            }
            var percentComplete = translationX / self.fullWidth
            if percentComplete < 0 {
                percentComplete = 0
            }
            self.updateInteractiveTransition(percentComplete)
            break;
        case UIGestureRecognizerState.Ended:
            break;
        case UIGestureRecognizerState.Cancelled:
            let isPanningRight = velocityX > 0
            
            if let coordinatorInteractionEnded = self.coordinatorInteractionEnded {
                coordinatorInteractionEnded(context: self.slidingViewController)
            }
            
            if isPanningRight && self.positiveLeftToRight {
                self.finishInteractiveTransition()
            } else if isPanningRight && !self.positiveLeftToRight {
                self.cancelInteractiveTransition()
            } else if !isPanningRight && self.positiveLeftToRight {
                self.cancelInteractiveTransition()
            } else if !isPanningRight && !self.positiveLeftToRight {
                self.finishInteractiveTransition()
            }
            break;
        default:
            break;
        }
    }
}