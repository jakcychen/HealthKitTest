//
//  DataVC.swift
//  HealthKitTest
//
//  Created by dev1 on 2018/9/19.
//  Copyright © 2018年 tw.com.cathaylife. All rights reserved.
//

import UIKit

class DataVC: UIViewController {
    
    var datas: [StepModel]!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.datas = AppDelegate.database.readData(tableName: AppDelegate.DB_TABLE_1)
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
        return self.datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stepCell")
        cell?.textLabel?.text = "Date: \(self.datas[indexPath.row].date) - Step: \(self.datas[indexPath.row].step)"
        cell?.detailTextLabel?.text = "Fetch: \(self.datas[indexPath.row].fetchTime)"
        cell?.detailTextLabel?.textColor = UIColor.lightGray
        cell?.layer.setValue(self.datas[indexPath.row].date, forKey: "dataDate")
        cell?.layer.setValue(self.datas[indexPath.row].fetchTime, forKey: "dataFetchTime")

        return cell!
    }
}








