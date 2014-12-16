//
//  ViewController.swift
//  ECSwiftSlidingViewController
//
//  Created by Mihael Isaev on 15.12.14.
//

import UIKit

class OneViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(self.slidingViewController().panGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

