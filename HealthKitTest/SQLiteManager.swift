//
//  SQLiteManager.swift
//  HealthKitTest
//
//  Created by dev1 on 2018/9/20.
//  Copyright © 2018年 tw.com.cathaylife. All rights reserved.
//

import Foundation
import SQLite3

class SQLiteManager {
    var dbPtr: OpaquePointer? = nil
    
    init?(path: String) {
        self.dbPtr = self.openDatabase(path: path)
    }
    
    // create or open database
    private func openDatabase(path: String) -> OpaquePointer {
        var connectdb: OpaquePointer? = nil
        var dbStatus: Int32 = SQLITE_ERROR
        
        dbStatus = sqlite3_open(path, &connectdb)
        if dbStatus != SQLITE_OK {
            //print("Unable to open database. Error code:", dbStatus)
        }
        return connectdb!
    }
    
    
    // create table
    func createTable(_ tableName: String, columnsInfo: [String]) -> Int32 {
        
        let sqlCmd: String = "create table if not exists \(tableName) "
            + "(\(columnsInfo.joined(separator: ",")))"
        
        var dbStatus: Int32 = SQLITE_ERROR
        dbStatus = sqlite3_exec(self.dbPtr, String(sqlCmd), nil, nil, nil)
        if dbStatus == SQLITE_OK {
            //print("Create table success.")
        }
        
        return dbStatus
    }
    
    // insert data into table
    func insert(_ tableName: String, rowInfo: [String: String]) -> Int32 {
        
        let sqlCmd: String = "insert into \(tableName) "
            + "(\(rowInfo.keys.joined(separator: ","))) "
            + "values (\(rowInfo.values.joined(separator: ",")))"
        
        var statement: OpaquePointer? = nil
        var dbStatus: Int32 = SQLITE_ERROR
        dbStatus = sqlite3_prepare_v2(self.dbPtr, String(sqlCmd), -1, &statement, nil)
        if dbStatus == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                //print("Insert data success.")
                return dbStatus
            }
            sqlite3_finalize(statement)
        }
        
        return dbStatus
    }
    
    // read data from table
    func readData(tableName: String)  -> [StepModel] {
        
        let sqlCmd: String = "SELECT * FROM \(tableName) ORDER BY DATE DESC, FETCH_TIME DESC"
        var statement: OpaquePointer? = nil
        var dbStatus: Int32 = SQLITE_ERROR
        dbStatus = sqlite3_prepare_v2(self.dbPtr, String(sqlCmd), -1, &statement, nil)
        if dbStatus != SQLITE_OK {
            return []
        }
        var resultArray: [StepModel] = []
        while sqlite3_step(statement) == SQLITE_ROW {

            let date = String(cString: sqlite3_column_text(statement, 0))
            let healthModel = StepModel(date: date)
            
            let step = String(cString: sqlite3_column_text(statement, 1))
            healthModel.step = step
            
            let fetchTime = String(cString: sqlite3_column_text(statement, 2))
            healthModel.fetchTime = fetchTime

            
            if tableName == AppDelegate.DB_TABLE_2 {
                let hardWareVersion = String(cString: sqlite3_column_text(statement, 3))
                healthModel.hardWareVersion = hardWareVersion
                
                let softWareVersion = String(cString: sqlite3_column_text(statement, 4))
                healthModel.softWareVersion = softWareVersion
                
                let productName = String(cString: sqlite3_column_text(statement, 5))
                healthModel.productName = productName
            }
            
            
            resultArray.append(healthModel)
        }
        sqlite3_finalize(statement)
        return resultArray
    }
}
