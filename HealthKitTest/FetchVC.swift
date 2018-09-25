//
//  FetchVC.swift
//  HealthKitTest
//
//  Created by dev1 on 2018/9/19.
//  Copyright © 2018年 tw.com.cathaylife. All rights reserved.
//

import UIKit
import MessageUI

class FetchVC: UIViewController {

    @IBOutlet weak var authButton: UIButton!
    @IBOutlet weak var fetchButton: UIButton!
    @IBOutlet weak var fetchingView: UIView!
    @IBOutlet weak var fetchingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    @IBAction func auth(_ sender: Any) {
        
        HealthKitManager.authorizeHealthKit { (authorized, error) in
            
            if !authorized  {
                return
            }
            self.authButton.setTitle("Authrized", for: .normal)
            self.authButton.isEnabled = false
            self.authButton.backgroundColor = UIColor.gray
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

extension FetchVC: MFMailComposeViewControllerDelegate {
    
    @IBAction func email(_ sender: Any) {
        
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localDateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        localDateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        let dateString = localDateFormatter.string(from: Date())
        mailVC.setSubject("HealthTest Report \(dateString)")
        
        mailVC.setToRecipients([
            "yjwang@cathaylife.com.tw",
            "frequency@cathaylife.com.tw",
            "sylas171@hotmail.com"
        ])
        
        let data = try? Data(contentsOf: AppDelegate.databasePath)
        mailVC.addAttachmentData(data!, mimeType: "application/octet-stream", fileName: "sqlite3.db")
        
        self.present(mailVC, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
   
        self.dismiss(animated: true, completion: nil)
    }
}


