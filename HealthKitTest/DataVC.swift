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
        segue.destination.title = cell.detailTextLabel?.text
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
        cell?.textLabel?.text = self.datas[indexPath.row].STEP
        cell?.detailTextLabel?.text = self.datas[indexPath.row].DATE
        
        
        return cell!
    }
}








