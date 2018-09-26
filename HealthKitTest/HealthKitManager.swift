//
//  MMLHealthInfoManager.swift
//  MyMobileLife
//
//  Created by dev1 on 2018/5/28.
//  Copyright © 2018年 CathayLife. All rights reserved.
//

import UIKit
import HealthKit

class HealthModel: Codable
{
    var DATE: String = ""
    var STEP: String = "0"
    var DISTANCE: String = "0"
    var HEART_RATE: String = ""
    
    init(date: String)
    {
        self.DATE = date
    }
}

class StepModel
{
    var date: String = ""
    var step: String = "0"
    var fetchTime: String = ""
    var softWareVersion: String = ""
    var hardWareVersion: String = ""
    var productName: String = ""
    
    init(date: String)
    {
        self.date = date
    }
}

let productName = [
    "iPhone6,1":  "iPhone 5s (A1433/A1453)",
    "iPhone6,2":  "iPhone 5s (A1457/A1518/A1530)",
    "iPhone7,1":  "iPhone 6 Plus",
    "iPhone7,2":  "iPhone 6",
    "iPhone8,1":  "iPhone 6s",
    "iPhone8,2":  "iPhone 6s Plus",
    "iPhone8,4":  "iPhone SE",
    "iPhone9,1":  "iPhone 7 (A1660/A1779/A1780)",
    "iPhone9,2":  "iPhone 7 Plus (A1661/A1785/A1786)",
    "iPhone9,3":  "iPhone 7 (A1778)",
    "iPhone9,4":  "iPhone 7 Plus (A1784)",
    "iPhone10,1": "iPhone 8 (A1863/A1906)",
    "iPhone10,2": "iPhone 8 Plus (A1864/A1898)",
    "iPhone10,3": "iPhone X (A1865/A1902)",
    "iPhone10,4": "iPhone 8 (A1905)",
    "iPhone10,5": "iPhone 8 Plus (A1897)",
    "iPhone10,6": "iPhone X (A1901)",
]

class HealthKitManager
{
    static var healthModels: [String: HealthModel] = [:]
    static let healthStore = HKHealthStore()
    static var fetchTimeString: String!
}

extension HealthKitManager
{
    static func fetchStepCount(duration: Int, completionHandler: @escaping (Bool) -> ())
    {        
        //
        let quantityType: HKQuantityType? = HKObjectType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount
        )
        
        //
        let predicate: NSPredicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
        
        //
        let calendar = Calendar.current
        var anchor: DateComponents = calendar.dateComponents(
            [.day, .month, .year, .hour],
            from: Date()
        )
        anchor.hour = 0
        let anchorDate = calendar.date(from: anchor)
        
        //
        var interval: DateComponents = DateComponents()
        interval.day = 1
        
        //
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType!,
            quantitySamplePredicate: predicate,
            options: [HKStatisticsOptions.cumulativeSum],
            anchorDate: anchorDate!,
            intervalComponents: interval
        )
        
        //
        query.initialResultsHandler = {
            query, results, error in
            
            //
            guard let statsCollection = results,
                      statsCollection.statistics().count > 0  // 0 if not authorize
            else
            {
                DispatchQueue.main.async {
                    completionHandler(false)
                }
                return
            }
            
            //
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: duration, to: endDate)
            else
            {
                return
            }
            
            statsCollection.enumerateStatistics(from: startDate, to: endDate)
            {(statistic, stop) in

                if let quantity = statistic.sumQuantity()
                {
                    let count = quantity.doubleValue(for: HKUnit.count())
                    
                    let date = statistic.startDate
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: date)
                    
                    var model = self.healthModels[dateString]
                    if model == nil {
                        model = HealthModel(date: dateString)
                    }
                    if count > 0 {
                        model?.STEP = String(lroundf(Float(count)))
                    }
                    self.healthModels[dateString] = model
                }
            }
            
            DispatchQueue.main.async {
                completionHandler(true)
            }
        }
        
        self.healthStore.execute(query)
    }
    
    static func fetchStepCountDetail(startDate: Date, endDate: Date, fetchTimeString: String, completionHandler: @escaping (Bool) -> ()) {
        
        let type = HKSampleType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount
        )
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: HKQueryOptions())
        let query = HKSampleQuery(sampleType: type!, predicate: predicate, limit: 0, sortDescriptors: nil) {
            query, results, error in
            
            if (results?.count)! > 0 {
                
                for result in results as! [HKQuantitySample] {
                    
                    let localDateFormatter = DateFormatter()
                    localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    localDateFormatter.locale = Locale(identifier: "zh_Hant_TW")
                    localDateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
                    let date = localDateFormatter.string(from: result.endDate)
                    let count = result.quantity.doubleValue(for: HKUnit.count())

                    let device = result.device
                    
                    let _ = AppDelegate.database.insert(
                        AppDelegate.DB_TABLE_2,
                        rowInfo: [
                            "DATE": "'\(date)'",
                            "STEP": String(Int(count)),
                            "FETCH_TIME": "'\(fetchTimeString)'",
                            "HARD_WARE_VERSION": "'\(device?.hardwareVersion! ?? "N/A")'",
                            "SOFT_WARE_VERSION": "'\(device?.softwareVersion! ?? "N/A")'",
                            "PRODUCT_NAME": "'\(productName[(device?.hardwareVersion)!] ?? "N/A")'"
                        ]
                    )
                }
            }
            
            DispatchQueue.main.async
            {
                completionHandler(true)
            }
        }
        
        self.healthStore.execute(query)
    }
    
    static func fetchDistance(completionHandler: @escaping () -> ())
    {
        //
        let quantityType = HKObjectType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning
        )
        
        //
        let predicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
        
        //
        let calendar = Calendar.current
        var anchor = calendar.dateComponents(
            [.day, .month, .year, .hour],
            from: Date()
        )
        anchor.hour = 0
        let anchorDate = calendar.date(from: anchor)
        
        //
        var interval = DateComponents()
        interval.day = 1
        
        //
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType!,
            quantitySamplePredicate: predicate,
            options: HKStatisticsOptions.cumulativeSum,
            anchorDate: anchorDate!,
            intervalComponents: interval
        )
        
        // Set the results handler
        query.initialResultsHandler = {
            query, results, error in
            
            guard let statsCollection = results else {
                return
            }
            
            let endDate = Date()
            
            guard let startDate = calendar.date(byAdding: .day, value: -39, to: endDate) else
            {
                return
            }
            
            statsCollection.enumerateStatistics(from: startDate, to: endDate)
            {(statistic, stop) in
                
                if let quantity = statistic.sumQuantity()
                {
                    var distance = quantity.doubleValue(for: HKUnit.meter())
                    distance = (distance * 100).rounded() / 100
                    
                    let date = statistic.startDate
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: date)
                    
                    var model = self.healthModels[dateString]
                    if model == nil {
                        model = HealthModel(date: dateString)
                    }
                    
                    if distance > 0 {
                        model?.STEP = String(Int(distance))
                    }
                    self.healthModels[dateString] = model
                    
                }
 
            }
            completionHandler()
        }
        self.healthStore.execute(query)
    }
    
    static func fetchHeartRate(completionHandler: @escaping () -> ())
    {
        //
        let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        
        //
        let calendar = Calendar.current
        var anchor = calendar.dateComponents([.day, .month, .year, .hour], from: Date())
        anchor.hour = 0
        let anchorDate = calendar.date(from: anchor)
        
        //
        var interval = DateComponents()
        interval.day = 1
        
        //
        //let predicate2 = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
        
        //
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType!,
            
            quantitySamplePredicate: nil,
            
            options: [HKStatisticsOptions.discreteMax, .discreteAverage, .discreteMin],
            
            anchorDate: anchorDate!,
            
            intervalComponents: interval
        )
        
        // Set the results handler
        query.initialResultsHandler = {
            query, results, error in
            
            guard let statsCollection = results else {
                return
            }
            
            let endDate = Date()
            
            guard let startDate = calendar.date(byAdding: .day, value: -39, to: endDate) else
            {
                return
            }
            
            statsCollection.enumerateStatistics(from: startDate, to: endDate, with:
            {(statistic, stop) in
                
                if let maxQquantity = statistic.maximumQuantity(), let minQuantity = statistic.minimumQuantity()
                {
                    let max = maxQquantity.doubleValue(for: HKUnit(from: "count/min"))
                    let min = minQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    
                    let date = statistic.startDate
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: date)
                    
                    if let model = self.healthModels[dateString]
                    {
                        model.HEART_RATE = "\(String(min))-\(String(max))"
                    }
                    else
                    {
                        let model = HealthModel(date: dateString)
                        model.HEART_RATE = "\(String(min))-\(String(max))"
                        self.healthModels[dateString] = model
                    }
                }
            })
            
            completionHandler()
        }
        self.healthStore.execute(query)
    }
}

extension HealthKitManager
{
    static func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void)
    {
        let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let healthInfoToRead: Set<HKObjectType> = [
            stepCount,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]

        let healthInfoToWrite: Set<HKSampleType> = []
        
        self.healthStore.requestAuthorization(toShare: healthInfoToWrite, read: healthInfoToRead)
        { (success, error) in
            
            // success here only means that iOS successfully asked the user about health kit access
            UserDefaults.standard.set(true, forKey: "isHealthKitAccessAsked")
            
            self.isHealthInfoAuthorized({ (isAuthorized) in
                completion(isAuthorized, nil)
            })
        }
    }
    
    static func isHealthInfoAuthorized(_ completionHandler: @escaping (Bool) -> ())
    {
        self.fetchStepCount(duration: -1, completionHandler: completionHandler)
    }
}

extension HealthKitManager
{
    static func updateHealthInfo(_ completionHandler: @escaping (Bool) -> ())
    {
        let fetchTime = Date()
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localDateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        localDateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        self.fetchTimeString = localDateFormatter.string(from: fetchTime)
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        self.fetchStepCount(duration: -39) {_ in dispatchGroup.leave() }
        
        dispatchGroup.enter()
        self.fetchDistance { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        self.fetchHeartRate { dispatchGroup.leave() }
        
        dispatchGroup.notify(queue: .main) { self.uploadDataToServer(completionHandler) }
    }
    
    private static func uploadDataToServer(_ completionHandler: @escaping (Bool) -> ())
    {
        for data in self.healthModels {
            let _ = AppDelegate.database.insert(
                AppDelegate.DB_TABLE_1,
                rowInfo: [
                    "DATE": "'\(data.value.DATE)'",
                    "STEP": "'\(data.value.STEP)'",
                    "FETCH_TIME": "'\(self.fetchTimeString!)'"
                ]
            )
        }

        let date = Date()
        self.fetchStepCountDetail(
            startDate: date.addingTimeInterval(40 *  -24 * 60 * 60),
            endDate: date.addingTimeInterval(24 * 60 * 60),
            fetchTimeString: self.fetchTimeString!,
            completionHandler: completionHandler
        )
    }
}






















