//
//  ReplaceRootSegue.swift
//  Asutomo
//
//  Created by Purbo Mohamad on 11/27/15.
//  Copyright © 2015 MapMotion. All rights reserved.
//

import UIKit

class ReplaceRootSegue: UIStoryboardSegue {

    override func perform() {
        
        let app = UIApplication.shared.delegate
        let window = ((app?.window)!)!
        
        if let destView = self.destination.view, let srcView = self.source.view {
            destView.frame = CGRect(x: 0.0, y: 20.0, width: srcView.bounds.width, height: srcView.bounds.height - 20.0)
            UIView.transition(
                with: window,
                duration: 1.0,
                options: .transitionCrossDissolve,
                animations: { 
                    window.insertSubview(destView, aboveSubview: srcView)
                }, completion: { finished in
                    srcView.removeFromSuperview()
                    window.rootViewController = self.destination
                })
        }
    }
    
}
