//
//  ECSlidingSegue.swift
//  ECSwiftSlidingViewController
//
//  Created by Mihael Isaev on 15.12.14.
//

import Foundation
import UIKit

extension UIViewController {
    func slidingViewController() -> ECSlidingViewController {
        return _ECSlidingViewControllerSharedInstance!
    }
    
    @IBAction func openSlidingLeftMenu(sender: AnyObject) {
        self.slidingViewController().toggleWithRightPosition()
    }
    
    @IBAction func openSlidingRightMenu(sender: AnyObject) {
        self.slidingViewController().toggleWithLeftPosition()
    }
}

class ECSlidingSegue: UIStoryboardSegue {
    var isUnwinding = false
    var skipSettingTopViewController = false
    
    override func perform() {
        let slidingViewController = self.sourceViewController.slidingViewController()
        
        if self.isUnwinding {
            if object_getClass(slidingViewController.underLeftViewController) === object_getClass(self.destinationViewController) {
                slidingViewController.anchorTopViewToRightAnimated(true)
            } else if object_getClass(slidingViewController.underRightViewController) === object_getClass(self.destinationViewController) {
                slidingViewController.anchorTopViewToLeftAnimated(true)
            }
        } else {
            if !self.skipSettingTopViewController {
                if let dest = self.destinationViewController as? UIViewController {
                    slidingViewController.setTopViewController(dest)
                }
            }
            slidingViewController.resetTopViewAnimated(true)
        }
    }
}