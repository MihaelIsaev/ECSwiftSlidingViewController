//
//  ECPercentDrivenInteractiveTransition.swift
//  ECSwiftSlidingViewController
//
//  Created by Mihael Isaev on 15.12.14.
//

import Foundation
import UIKit

class ECPercentDrivenInteractiveTransition: NSObject, UIViewControllerInteractiveTransitioning {
    
    var transitionContext: UIViewControllerContextTransitioning!
    
    var animationController: UIViewControllerAnimatedTransitioning!
    var percentComplete: CGFloat = 0
    var isActive = false
    
    func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.isActive = true
        self.transitionContext = transitionContext
        
        var containerLayer = self.transitionContext.containerView().layer
        self.removeAnimationsRecursively(containerLayer)
        self.animationController.animateTransition(transitionContext)
        self.updateInteractiveTransition(0)
    }
    
    func updateInteractiveTransition(percentComplete: CGFloat) {
        if !self.isActive {
            return
        }
        
        self.transitionContext.updateInteractiveTransition(self.percentComplete)

        var boundedPercentage: CGFloat
        if percentComplete > 1 {
            boundedPercentage = 1
        } else if percentComplete < 0 {
            boundedPercentage = 0
        } else {
            boundedPercentage = percentComplete
        }
        self.percentComplete = boundedPercentage
        
        let pausedTime = CFTimeInterval(CGFloat(self.animationController.transitionDuration(self.transitionContext)) * self.percentComplete)
        
        let layer = self.transitionContext.containerView().layer
        layer.speed = 0
        layer.timeOffset = pausedTime
    }
    
    func cancelInteractiveTransition() {
        if !self.isActive {
            return
        }
        
        self.transitionContext.cancelInteractiveTransition()
        
        let displayLink = CADisplayLink(target: self, selector: "reversePausedAnimation:")
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func finishInteractiveTransition() {
        if !self.isActive {
            return
        }
        
        self.isActive = false
        self.transitionContext.finishInteractiveTransition()
        
        let layer = self.transitionContext.containerView().layer
        let pausedTime = layer.timeOffset
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        layer.beginTime = timeSincePause
    }
    
    //MARK: - CADisplayLink action
    
    func reversePausedAnimation(displayLink: CADisplayLink) {
        let percentInterval = displayLink.duration / self.animationController.transitionDuration(self.transitionContext)
        println("reversePausedAnimation")
        self.percentComplete -= CGFloat(percentInterval)
        
        if self.percentComplete <= 0 {
            self.percentComplete = 0
            displayLink.invalidate()
        }
        
        self.updateInteractiveTransition(self.percentComplete)
        
        if self.percentComplete == 0 {
            self.isActive = false
            let layer = self.transitionContext.containerView().layer
            layer.removeAllAnimations()
            layer.speed = 0.999
        }
    }
    
    //MARK: - Private
    
    func removeAnimationsRecursively(layer: CALayer) {
        if let sublayers = layer.sublayers {
            for subLayer in sublayers {
                if let sl = subLayer as? CALayer {
                    sl.removeAllAnimations()
                    self.removeAnimationsRecursively(sl)
                }
            }
        }
    }
}