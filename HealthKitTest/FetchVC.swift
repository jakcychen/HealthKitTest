//
//  FetchVC.swift
//  HealthKitTest
//
//  Created by dev1 on 2018/9/19.
//  Copyright © 2018年 tw.com.cathaylife. All rights reserved.
//

import UIKit

class FetchVC: UIViewController {

    @IBOutlet weak var authButton: UIButton!
    @IBOutlet weak var fetchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func auth(_ sender: Any)
    {
        self.authButton.setTitle("Auth in progress", for: .normal)
        HealthKitManager.authorizeHealthKit { (authorized, error) in
            if !authorized  {
                return
            }
            self.authButton.setTitle("Authrized", for: .normal)
            self.authButton.isEnabled = false
        }
    }

    @IBAction func fetch(_ sender: Any)
    {
        self.fetchButton.setTitle("fetching in progress", for: .normal)
        HealthKitManager.authorizeHealthKit { (authorized, error) in
            if !authorized  {
                return
            }
            HealthKitManager.updateHealthInfo { (success) in
                if !success {
                    return
                }
                self.fetchButton.setTitle("fetch", for: .normal)
            }
        }
    }

}
