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
    static let healthStore = HKHealthStore()
    static var fetchTimeString: String!
}

extension HealthKitManager
{
    static func fetchStepCount(duration: Int, completionHandler: @escaping (Bool, [String: String]) -> ())
    {        
        let quantityType: HKQuantityType? = HKObjectType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount
        )
        
        let calendar = Calendar.current
        var anchor: DateComponents = calendar.dateComponents(
            [.day, .month, .year, .hour],
            from: Date()
        )
        anchor.hour = 0
        let anchorDate = calendar.date(from: anchor)
        
        var interval: DateComponents = DateComponents()
        interval.day = 1

        
        // query source to create predicate
        let validateSource: NSMutableSet = NSMutableSet()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        let sourceQuery = HKSourceQuery(sampleType: quantityType!, samplePredicate: nil) { (query, sources, error) in
            if sources == nil {
                return
            }
            for source in sources! {
                if source.name != "捷徑" {
                    validateSource.add(source)
                }
            }
            dispatchGroup.leave()
        }
        self.healthStore.execute(sourceQuery)
        
        
        //
        dispatchGroup.notify(queue: .main) {

            let predicate1: NSPredicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
            let predicate2 = NSPredicate(format: "%K IN %@", HKPredicateKeyPathSource, validateSource)
            //let predicate2 = NSPredicate(format: "sourceRevision.source.name == %@", "捷徑")  // crash, not support keypath
            //let predicate2 = NSPredicate(format: "%K != %@", HKPredicateKeyPathSource, HKSource.default())  // can't create customize source
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType!,
                quantitySamplePredicate: compoundPredicate,
                options: [HKStatisticsOptions.cumulativeSum],
                anchorDate: anchorDate!,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = {
                query, results, error in
                
                var stepData: [String: String] = [:]
                guard let statsCollection = results,
                    statsCollection.statistics().count > 0  // 0 if not authorize
                    else
                {
                    // not authorize
                    DispatchQueue.main.async {
                        completionHandler(false, stepData)
                    }
                    return
                }
                
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
                        stepData[dateString] = String(lroundf(Float(count)))
                    }
                }
                
                DispatchQueue.main.async {
                    completionHandler(true, stepData)
                }
            }
            
            self.healthStore.execute(query)
        }
    }
}

extension HealthKitManager
{
    static func fetchDistance(completionHandler: @escaping ([String: String]) -> ())
    {
        let quantityType = HKObjectType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning
        )
        
        let predicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
        
        let calendar = Calendar.current
        var anchor = calendar.dateComponents(
            [.day, .month, .year, .hour],
            from: Date()
        )
        anchor.hour = 0
        let anchorDate = calendar.date(from: anchor)
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType!,
            quantitySamplePredicate: predicate,
            options: HKStatisticsOptions.cumulativeSum,
            anchorDate: anchorDate!,
            intervalComponents: interval
        )
        
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
            
            var distanceData: [String: String] = [:]
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
                    
                    distanceData[dateString] = String(lroundf(Float(distance)))
                }
            }
            completionHandler(distanceData)
        }
        self.healthStore.execute(query)
    }
}


extension HealthKitManager
{
    static func fetchHeartRate(completionHandler: @escaping ([String: String]) -> ())
    {
        let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        
        let calendar = Calendar.current
        var anchor = calendar.dateComponents([.day, .month, .year, .hour], from: Date())
        anchor.hour = 0
        let anchorDate = calendar.date(from: anchor)
        
        var interval = DateComponents()
        interval.day = 1
        
        //let predicate2 = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType!,
            
            quantitySamplePredicate: nil,
            
            options: [HKStatisticsOptions.discreteMax, .discreteAverage, .discreteMin],
            
            anchorDate: anchorDate!,
            
            intervalComponents: interval
        )
        
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
            
            var heartrateData: [String: String] = [:]
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
                        
                        heartrateData[dateString] = "\(String(min))-\(String(max))"
                    }
            })
            
            completionHandler(heartrateData)
        }
        self.healthStore.execute(query)
    }
}


extension HealthKitManager
{
    static func updateHealthInfo(stepData: [String: String], completionHandlerAfterUpdate: @escaping (Bool) -> ())
    {
        let fetchTime = Date()
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localDateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        localDateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        self.fetchTimeString = localDateFormatter.string(from: fetchTime)
        
        let dispatchGroup = DispatchGroup()

        var distanceData: [String: String] = [:]
        dispatchGroup.enter()
        self.fetchDistance { (distances) in
            distanceData = distances
            dispatchGroup.leave()
        }

        var heartrateData: [String: String] = [:]
        dispatchGroup.enter()
        self.fetchHeartRate { (heartrates) in
            heartrateData = heartrates
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            
            var healthModels: [String: HealthModel] = [:]

            var model: HealthModel
            
            for (date, step) in stepData {

                if let data = healthModels[date] {
                    data.STEP = step
                } else {
                    model = HealthModel(date: date)
                    model.STEP = step
                    healthModels[date] = model
                }
            }
            
            for (date, distance) in distanceData {

                if let data = healthModels[date] {
                    data.DISTANCE = distance
                } else {
                    model = HealthModel(date: date)
                    model.DISTANCE = distance
                    healthModels[date] = model
                }
            }

            for (date, heartrate) in heartrateData {

                if let data = healthModels[date] {
                    data.HEART_RATE = heartrate
                } else {
                    model = HealthModel(date: date)
                    model.HEART_RATE = heartrate
                    healthModels[date] = model
                }
            }

            self.uploadDataToServer(healthModels: healthModels, completionHandlerAfterUpdate: completionHandlerAfterUpdate)
        }
    }
}
extension HealthKitManager
{
    private static func uploadDataToServer(healthModels: [String: HealthModel], completionHandlerAfterUpdate: @escaping (Bool) -> ())
    {
        for data in healthModels {
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
            startDate: date.addingTimeInterval(41 *  -24 * 60 * 60),
            endDate: date.addingTimeInterval(24 * 60 * 60),
            fetchTimeString: self.fetchTimeString!,
            completionHandler: completionHandlerAfterUpdate
        )
    }
}

extension HealthKitManager
{
    static func fetchStepCountDetail(startDate: Date, endDate: Date, fetchTimeString: String, completionHandler: @escaping (Bool) -> ()) {
        
        let type = HKSampleType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount
        )
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: HKQueryOptions())
        let query = HKSampleQuery(sampleType: type!, predicate: predicate, limit: 0, sortDescriptors: nil) {
            query, results, error in
            
            if (results?.count)! > 0 {
                
                for result in results as! [HKQuantitySample] {

                    //print(result.sourceRevision.source.bundleIdentifier)
                    //print(result.sourceRevision.source.name)
                    
                    
                    let localDateFormatter = DateFormatter()
                    localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    localDateFormatter.locale = Locale(identifier: "zh_Hant_TW")
                    localDateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
                    let date = localDateFormatter.string(from: result.endDate)
                    let count = result.quantity.doubleValue(for: HKUnit.count())
                    
                    let device = result.device
                    let hardwareVersion = device?.hardwareVersion ?? "N/A"
                    let softwareVersion = device?.softwareVersion ?? "N/A"
                    
                    let _ = AppDelegate.database.insert(
                        AppDelegate.DB_TABLE_2,
                        rowInfo: [
                            "DATE": "'\(date)'",
                            "STEP": String(Int(count)),
                            "FETCH_TIME": "'\(fetchTimeString)'",
                            "HARD_WARE_VERSION": "'\(hardwareVersion)'",
                            "SOFT_WARE_VERSION": "'\(softwareVersion)'",
                            "PRODUCT_NAME": "'\(productName[hardwareVersion] ?? "N/A")'"
                        ]
                    )
                }
            }
            
            DispatchQueue.main.async {
                completionHandler(true)
            }
        }
        
        self.healthStore.execute(query)
    }
}

extension HealthKitManager
{
    static func askAuthorizeHealthKit(askAuthorizeCompletion: @escaping () -> Void)
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
            
            askAuthorizeCompletion()
        }
    }
}


























