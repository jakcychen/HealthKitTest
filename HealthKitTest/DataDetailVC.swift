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
    var tile: String!
    var datas: [StepModel]!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var temp: [StepModel] = []
        for data in AppDelegate.database.readData(tableName: AppDelegate.DB_TABLE_2) {
            if data.DATE.contains(self.title!) {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "stepDetailCell")
        cell?.textLabel?.text = self.datas[indexPath.row].STEP
        cell?.detailTextLabel?.text = self.datas[indexPath.row].DATE
        
        return cell!
    }
}
