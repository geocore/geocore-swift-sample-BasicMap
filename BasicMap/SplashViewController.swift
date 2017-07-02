//
//  SplashViewController.swift
//  BasicMap
//
//  Created by Purbo Mohamad on 2017/03/29.
//  Copyright © 2017 Geocore. All rights reserved.
//

import UIKit
import PromiseKit
import GeocoreKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Login to Geocore
        Geocore.sharedInstance.loginWithDefaultUser()
            .then { accessToken -> Void in
                debugPrint("[INFO] Logged in to Geocore successfully, with access token = \(accessToken), userId = \(Geocore.sharedInstance.userId)")
                // wait for 1 seconds and move to the next screen (for now)
                Timer.scheduledTimer(
                    timeInterval: 1.0,
                    target: self,
                    selector: #selector(SplashViewController.toTopScreen),
                    userInfo: nil,
                    repeats: false)
            }
            .catch { error in
                print("[ERROR] Error connecting/logging in -> \(error)")
            }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toTopScreen() {
        self.performSegue(withIdentifier: "splashToTop", sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
