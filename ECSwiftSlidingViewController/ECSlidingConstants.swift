//
//  ECSlidingConstants.swift
//  ECSwiftSlidingViewController
//
//  Created by Mihael Isaev on 15.12.14.
//

import Foundation

let ECTransitionContextTopViewControllerKey: String = "ECTransitionContextTopViewControllerKey"
let ECTransitionContextUnderLeftControllerKey: String = "ECTransitionContextUnderLeftControllerKey"
let ECTransitionContextUnderRightControllerKey: String = "ECTransitionContextUnderRightControllerKey"

enum ECSlidingViewControllerOperation {
    /** The top view is not moving. */
    case None
    /** The top view is moving from center to left. */
    case AnchorLeft
    /** The top view is moving from center to right. */
    case AnchorRight
    /** The top view is moving from left to center. */
    case ResetFromLeft
    /** The top view is moving from right to center. */
    case ResetFromRight
}

enum ECSlidingViewControllerTopViewPosition {
    /** The top view is on anchored to the left */
    case AnchoredLeft
    /** The top view is on anchored to the right */
    case AnchoredRight
    /** The top view is centered */
    case Centered
}

enum ECSlidingViewControllerAnchoredGesture: NSInteger {
    /** Nothing is done to the top view while it is anchored. */
    case None     = 0
    /** The sliding view controller's `panGesture` is made available while the top view is anchored. This option is only relevant for transitions that use the default interactive transition. It is also only used if the sliding view controller's `panGesture` is enabled and added to a view. */
    case Panning  = 1
    /** The sliding view controller's `resetTapGesture` is made available while the top view is anchored. */
    case Tapping  = 2
    /** Any gestures set on the sliding view controller's `customAnchoredGestures` property are made available while the top view is anchored. These gestures are temporarily removed from their current view. */
    case Custom   = 4
    /** All user interactions on the top view are disabled when anchored. This takes precedence when combined with any other option. */
    case Disabled = 8
}