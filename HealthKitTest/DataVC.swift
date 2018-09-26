//
//  DataVC.swift
//  HealthKitTest
//
//  Created by dev1 on 2018/9/19.
//  Copyright © 2018年 tw.com.cathaylife. All rights reserved.
//

import UIKit
import MessageUI

class DataVC: UIViewController {
    
    var datas: [StepModel]!
    var searchResults: [StepModel] = []
    var tableViewData: [StepModel] = []

    var isSearching: Bool = false
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        self.datas = AppDelegate.database.readData(tableName: AppDelegate.DB_TABLE_1)
        self.tableViewData = self.datas
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let cell = sender as! UITableViewCell
        (segue.destination as! DataDetailVC).dataDate = cell.layer.value(forKey: "dataDate") as! String
        (segue.destination as! DataDetailVC).dataFetchTime = cell.layer.value(forKey: "dataFetchTime") as! String
    }
}

extension DataVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let date = self.tableViewData[indexPath.row].date
        let fetchTime = self.tableViewData[indexPath.row].fetchTime
        var rawDataNumber = 0
        for data in AppDelegate.database.readData(tableName: AppDelegate.DB_TABLE_2) {
              if data.date.contains(date) && data.fetchTime.contains(fetchTime) {
                rawDataNumber += Int(data.step)!
            }
        }
        

        let cell = tableView.dequeueReusableCell(withIdentifier: "stepCell")

        let attributedString = NSMutableAttributedString(string: "\(date)    Step: ")
        attributedString.append(
            NSAttributedString(
                string: "\(self.tableViewData[indexPath.row].step) ",
                attributes: [ NSAttributedStringKey.foregroundColor : self.view.tintColor]
            )
        )
        attributedString.append(NSAttributedString(string: "(\(rawDataNumber))"))
        cell?.textLabel?.attributedText = attributedString
        
        cell?.detailTextLabel?.text = "Fetch: \(self.datas[indexPath.row].fetchTime)"
        cell?.detailTextLabel?.textColor = UIColor.lightGray
        
        cell?.layer.setValue(self.tableViewData[indexPath.row].date, forKey: "dataDate")
        cell?.layer.setValue(self.tableViewData[indexPath.row].fetchTime, forKey: "dataFetchTime")

        

        
        return cell!
    }
}

extension DataVC: MFMailComposeViewControllerDelegate {
    
    @IBAction func emailData(_ sender: Any) {
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



