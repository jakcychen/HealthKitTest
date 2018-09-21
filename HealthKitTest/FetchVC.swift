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
    @IBOutlet weak var fetchingView: UIView!
    @IBOutlet weak var fetchingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func auth(_ sender: Any)
    {
        HealthKitManager.authorizeHealthKit { (authorized, error) in
            if !authorized  {
                return
            }
            self.authButton.setTitle("Authrized", for: .normal)
            self.authButton.isEnabled = false
            self.authButton.backgroundColor = UIColor.gray
        }
    }

    @IBAction func fetch(_ sender: Any)
    {
        self.fetchButton.setTitle("fetching in progress", for: .normal)
        self.fetchingIndicator.startAnimating()
        self.view.window?.addSubview(self.fetchingView)
        
        HealthKitManager.authorizeHealthKit { (authorized, error) in
            if !authorized  {
                return
            }
            
            HealthKitManager.updateHealthInfo { (success) in
                if !success {
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.fetchButton.setTitle("fetch", for: .normal)
                    self.fetchingIndicator.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                }
            }
        }
    }

}
