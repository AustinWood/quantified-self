//
//  ViewController.swift
//  quantified-self
//
//  Created by Austin Wood on 5/19/17.
//  Copyright © 2017 Austin Wood. All rights reserved.
//

import UIKit
import Just
import HealthKit

// https://github.com/JustHTTP/Just

class ViewController: UIViewController {
    
    let healthKitStore = HKHealthStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        requestHKPerimssions()
    }
    
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func submitPressed(_ sender: Any) {
        getHeartRate()
//        Just.post(
//            "https://austinbio.herokuapp.com/api/heart_rates",
//            data: ["value": 1]
//        ) { r in
//            print(r)
//        }
    }
    
    func requestHKPerimssions() {
        if HKHealthStore.isHealthDataAvailable() {
            print("HK data is available")
            let shareTypes = Set<HKSampleType>()
            var readTypes = Set<HKObjectType>()
            readTypes.insert(HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!)
            healthKitStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) -> Void in
                if success {
                    print("Successfully requested HK authorization")
                } else {
                    print("Failed to authorize HK")
                }
                if let error = error {
                    print(error)
                }
            }
        } else {
            print("HK data is NOT available")
        }
    }
    
    func getHeartRate() {
        let tHeartRate = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        let tHeartRateQuery = HKSampleQuery(sampleType: tHeartRate!, predicate:.none, limit: 0, sortDescriptors: nil) { query, results, error in
            if (results?.count)! > 0 {
                var string:String = ""
                for result in results as! [HKQuantitySample] {
                    let HeartRate = result.quantity
                    string = "\(HeartRate)"
                    print(string)
                }
            }
        }
        self.healthKitStore.execute(tHeartRateQuery)
        print(tHeartRate)
    }
}
