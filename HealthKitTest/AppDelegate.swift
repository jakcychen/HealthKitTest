//
//  AppDelegate.swift
//  HealthKitTest
//
//  Created by dev1 on 2018/9/19.
//  Copyright © 2018年 tw.com.cathaylife. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static var databasePath: URL!
    static var database: SQLiteManager!
    static var DB_NAME: String = "sqlite3.db"
    static var DB_TABLE_1: String = "Step"
    static var DB_TABLE_2: String = "StepDetail"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        Fabric.with([Crashlytics.self])
        
        let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        AppDelegate.databasePath = directoryPath.appendingPathComponent(AppDelegate.DB_NAME)
        AppDelegate.database = SQLiteManager(path: AppDelegate.databasePath.absoluteString)
        if AppDelegate.database != nil {
            let _ = AppDelegate.database!.createTable(
                AppDelegate.DB_TABLE_1,
                columnsInfo: [
                    "DATE TEXT",
                    "STEP TEXT",
                    "FETCH_TIME TEXT"
                ]
            )
            
            let _ = AppDelegate.database!.createTable(
                AppDelegate.DB_TABLE_2,
                columnsInfo: [
                    "DATE TEXT",
                    "STEP TEXT",
                    "FETCH_TIME TEXT",
                    "HARD_WARE_VERSION",
                    "SOFT_WARE_VERSION",
                    "PRODUCT_NAME"
                ]
            )
        }
        
        return true
    }
}







