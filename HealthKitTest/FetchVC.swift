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
    @IBOutlet weak var versioinLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecomeActive),
            name: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil
        )
        
        let buildNumber = Bundle.main.infoDictionary!["CFBundleVersion"]
        self.versioinLabel.text = buildNumber as! String
    }
    
    @objc func appBecomeActive() {

        HealthKitManager.isHealthInfoAuthorized {
            (isBinded) in
            
            if !isBinded {
                self.disableFetching()
                return
            }
            
            self.enableFetching()
        }
    }
    
    func disableFetching() {
        self.authButton.isEnabled = true
        self.authButton.backgroundColor = self.view.tintColor
        self.fetchButton.isEnabled = false
        self.fetchButton.backgroundColor = UIColor.gray
    }
    
    func enableFetching() {
        self.authButton.setTitle("Authorized", for: .normal)
        self.authButton.isEnabled = false
        self.authButton.backgroundColor = UIColor.gray
        self.fetchButton.isEnabled = true
        self.fetchButton.backgroundColor = self.view.tintColor
    }
    
    @IBAction func auth(_ sender: Any) {
        
        if UserDefaults.standard.bool(forKey: "isHealthKitAccessAsked") {
            
            let title: String = "Need Authorize"
            let message: String = "HealthKitTest need authorize to access healthKit"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { alert in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(cancelAction)
            
            let setAction = UIAlertAction(title: "Authorize", style: .default) { alert in
                if let settingsURL = URL(string: "App-prefs:") {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            }
            alert.addAction(setAction)
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        HealthKitManager.authorizeHealthKit { (authorized, error) in
            
            if !authorized  {
                self.disableFetching()
                return
            }
            self.enableFetching()
        }
    }

    @IBAction func fetch(_ sender: Any) {
        
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



