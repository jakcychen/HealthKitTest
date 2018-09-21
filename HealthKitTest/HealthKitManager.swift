//
//  MMLHealthInfoManager.swift
//  MyMobileLife
//
//  Created by dev1 on 2018/5/28.
//  Copyright © 2018年 CathayLife. All rights reserved.
//

import UIKit
import HealthKit

class StepModel
{
    var date: String = ""
    var step: String = "0"
    var fetchTime: String = ""
    
    init(date: String)
    {
        self.date = date
    }
}

class HealthKitManager
{
    static let healthStore = HKHealthStore()
}

extension HealthKitManager
{
    static func fetchStepCount(duration: Int, completionHandler: @escaping (Bool) -> ())
    {
        print("fetchStepCount")
        let fetchTime = Date()
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localDateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        localDateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        let fetchTimeString = localDateFormatter.string(from: fetchTime)
        
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
                DispatchQueue.main.async
                {
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

                    print("\(dateString) - \(count) - \(fetchTimeString)")
                    
                    let _ = AppDelegate.database.insert(
                        AppDelegate.DB_TABLE_1,
                        rowInfo: [
                            "DATE": "'\(dateString)'",
                            "STEP": String(Int(count)),
                            "FETCH_TIME": "'\(fetchTimeString)'"
                        ]
                    )
                }
            }
            
            self.fetchStepCountDetail(startDate: startDate.addingTimeInterval(8 * 60 * 60), endDate: endDate.addingTimeInterval(8 * 60 * 60), fetchTimeString: fetchTimeString, completionHandler: completionHandler)
            
//            DispatchQueue.main.async
//            {
//                completionHandler(true)
//            }
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
                    
                    //let date = result.endDate.addingTimeInterval(8*60*60)
                    let fetchTime = Date()
                    let localDateFormatter = DateFormatter()
                    localDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    localDateFormatter.locale = Locale(identifier: "zh_Hant_TW")
                    localDateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
                    let date = localDateFormatter.string(from: result.endDate)
                    
                    
                    
                    let count = result.quantity.doubleValue(for: HKUnit.count())
                    let _ = AppDelegate.database.insert(
                        AppDelegate.DB_TABLE_2,
                        rowInfo: [
                            "DATE": "'\(date)'",
                            "STEP": String(Int(count)),
                            "FETCH_TIME": "'\(fetchTimeString)'"
                        ]
                    )
                    print("\(date) - \(count) - \(fetchTimeString)")
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
        print("fetchDistance")

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
                /*
                if let quantity = statistic.sumQuantity()
                {
                    var distance = quantity.doubleValue(for: HKUnit.meter())
                    distance = (distance * 100).rounded() / 100
                    
                    let date = statistic.startDate
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: date)
                }
                */
            }
            completionHandler()
        }
        self.healthStore.execute(query)
    }
    
    static func fetchHeartRate(completionHandler: @escaping () -> ())
    {
        print("fetchHeartRate")

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
                /*
                if let maxQquantity = statistic.maximumQuantity(), let minQuantity = statistic.minimumQuantity()
                {
                    
                    let max = maxQquantity.doubleValue(for: HKUnit(from: "count/min"))
                    let min = minQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    
                    let date = statistic.startDate
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: date)
                }
                */
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
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        self.fetchStepCount(duration: -5) {_ in dispatchGroup.leave() }
        
        dispatchGroup.enter()
        self.fetchDistance { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        self.fetchHeartRate { dispatchGroup.leave() }
        
        dispatchGroup.notify(queue: .main) { self.uploadDataToServer(completionHandler) }
    }
    
    private static func uploadDataToServer(_ completionHandler: @escaping (Bool) -> ())
    {
        print("uploadDataToServer")
        completionHandler(true)
    }
}






















