//
//  DataDetailVC.swift
//  HealthKitTest
//
//  Created by dev1 on 2018/9/20.
//  Copyright © 2018年 tw.com.cathaylife. All rights reserved.
//

import UIKit

class DataDetailVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var dataDate: String!
    var dataFetchTime: String!
    var datas: [StepModel]!
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.navigationItem.title = self.dataDate
        self.navigationItem.prompt = "Fetch at: \(self.dataFetchTime!)"
        
        var temp: [StepModel] = []
        for data in AppDelegate.database.readData(tableName: AppDelegate.DB_TABLE_2) {
            
            if data.date.contains(self.dataDate!) && data.fetchTime.contains(self.dataFetchTime!) {
                temp.append(data)
            }
        }
        self.datas = temp
        self.tableView.reloadData()
    }
}

extension DataDetailVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "stepDetailCell") as! DataDetailCell
        
        cell.stepCount.text = "\(self.datas[indexPath.row].step)"
        
        var date = self.datas[indexPath.row].date.components(separatedBy: " ")
        cell.stepTime.text = "\(date[1])"
        
        let productName = self.datas[indexPath.row].productName
        cell.deviceInfo.text = productName
        
        let softWareVersion = self.datas[indexPath.row].softWareVersion
        cell.systemInfo.text = softWareVersion
        
        return cell
    }
}

class DataDetailCell: UITableViewCell {
    @IBOutlet weak var stepCount: UILabel!
    @IBOutlet weak var stepTime: UILabel!
    
    @IBOutlet weak var systemInfo: UILabel!
    @IBOutlet weak var deviceInfo: UILabel!
}
