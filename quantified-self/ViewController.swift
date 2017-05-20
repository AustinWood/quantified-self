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
import CoreLocation
import MapKit

// https://github.com/JustHTTP/Just

class ViewController: UIViewController {

    let healthKitStore = HKHealthStore()
    var value: Int?
    var date_str: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        requestHKPerimssions()
    }
    
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func submitPressed(_ sender: Any) {
        getHeartRate()
        checkForResult()
    }
    
    //////
    
    fileprivate var locations = [MKPointAnnotation]()
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self as! CLLocationManagerDelegate
        manager.requestAlwaysAuthorization()
        return manager
    }()
    
    
    
    
    
    //////
    
    func checkForResult() {
        if value != nil && date_str != nil {
            postData()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.checkForResult()
            })
        }
    }
    
    func postData() {
        let data = ["value": value!, "date_str": date_str!] as [String : Any]
        print(data)
        Just.post(
            "https://austinbio.herokuapp.com/api/heart_rates",
            data: data
        ) { r in
            print(r)
        }
        value = nil
        date_str = nil
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
//                var string:String = ""
//                for result in results as! [HKQuantitySample] {
//                    let HeartRate = result.quantity
//                    string = "\(HeartRate)"
//                    print(string)
//                    print(result.startDate)
//                }
                let result = results?.last as! HKQuantitySample
                self.value = Int(result.quantity.doubleValue(for: HKUnit(from: "count/min")))
                self.date_str = "\(result.startDate)"
            }
        }
        self.healthKitStore.execute(tHeartRateQuery)
    }
}











// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            return
        }
        
        // Add another annotation to the map.
        let annotation = MKPointAnnotation()
        annotation.coordinate = mostRecentLocation.coordinate
        
        // Also add to our map so we can remove old values later
        self.locations.append(annotation)
        
        // Remove values if the array is too big
        while locations.count > 100 {
            let annotationToRemove = self.locations.first!
            self.locations.remove(at: 0)
            
            // Also remove from the map
//            mapView.removeAnnotation(annotationToRemove)
        }
        
        if UIApplication.shared.applicationState == .active {
//            mapView.showAnnotations(self.locations, animated: true)
            print("App is in foreground. New location is %@", mostRecentLocation)
        } else {
            print("App is backgrounded. New location is %@", mostRecentLocation)
        }
    }
    
}
