//
//  customSegue.swift
//  moonday
//
//  Created by viewdidload on 2017. 10. 6..
//  Copyright © 2017년 ViewDidLoad. All rights reserved.
//

import UIKit

class goLeftTransitionSegue: UIStoryboardSegue {
    override func perform() {
        source.view.superview?.insertSubview(destination.view, aboveSubview: source.view)
        // 초기 위치
        destination.view.transform = CGAffineTransform(translationX: -source.view.frame.size.width, y: 0)
        UIView.animate(withDuration: 0.2, delay: 0.01, options: [.curveEaseInOut], animations: {
            self.destination.view.transform = CGAffineTransform(translationX: 0, y: 0)
            self.source.view.transform = CGAffineTransform(translationX: self.source.view.frame.size.width/3, y: 0)
        }) { (finished) in
            self.source.present(self.destination, animated: false, completion: nil)
        }
    }
}

class goRightTransitionSegue: UIStoryboardSegue {
    override func perform() {
        source.view.superview?.insertSubview(destination.view, aboveSubview: source.view)
        // 초기 위치
        source.view.transform = CGAffineTransform(translationX: 0, y: 0)
        destination.view.transform = CGAffineTransform(translationX: source.view.frame.size.width, y: 0)
        UIView.animate(withDuration: 0.2, delay: 0.01, options: [.curveEaseInOut], animations: {
            self.source.view.transform = CGAffineTransform(translationX: -self.source.view.frame.size.width/3, y: 0)
            self.destination.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { (finished) in
            self.source.present(self.destination, animated: false, completion: nil)
        }
    }
}

