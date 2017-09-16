//
//  ViewController.swift
//  quantified-self
//
//  Created by Austin Wood on 5/19/17.
//  Copyright © 2017 Austin Wood. All rights reserved.
//
/////////////////
///// TO DO /////
//
// update label in iOS app with data
// don't make POST request if entry.last hasn't changed
// fetch heart rate data while phone is locked
//
/////////////////

import UIKit
import Just
import HealthKit
import AVFoundation

// https://github.com/JustHTTP/Just
// https://www.raywenderlich.com/143128/background-modes-tutorial-getting-started

class ViewController: UIViewController {

    let healthKitStore = HKHealthStore()
    var value: Int?
    var date_str: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        requestHKPerimssions()
        initializeAudioPlayer()
    }
    
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
            
//  https://developer.apple.com/reference/healthkit
//  Because the HealthKit store is encrypted, your app cannot read data from the store when the phone is locked. This means your app may not be able to access the store when it is launched in the background.
            
            if results != nil {
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
            } else {
                print("results was nil")
            }
            
        }
        self.healthKitStore.execute(tHeartRateQuery)
    }
    
    ////////////////////////////
    ////////////////////////////
    ///// BACKGROUND AUDIO /////
    ////////////////////////////
    ////////////////////////////
    
    lazy var player: AVQueuePlayer = self.makePlayer()
    
    private lazy var songs: [AVPlayerItem] = {
        let songNames = ["1-hour-of-silence"]
        return songNames.map {
            let url = Bundle.main.url(forResource: $0, withExtension: "mp3")!
            return AVPlayerItem(url: url)
        }
    }()
    
    func initializeAudioPlayer() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayAndRecord,
                with: .defaultToSpeaker)
        } catch {
            print("Failed to set audio session category.  Error: \(error)")
        }
        
        let seconds: Int64 = 10
        let preferredTimeScale: Int32 = 1
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(seconds, preferredTimeScale), queue: DispatchQueue.main) {
            [weak self] time in
            let timeString = String(format: "%02.2f", CMTimeGetSeconds(time))
            
            if UIApplication.shared.applicationState == .active {
                print("Foreground: \(timeString)")
            } else {
                print("Background: \(timeString)")
            }
            
            self?.getHeartRate()
            self?.checkForResult()
        }
        
        playAudio()
    }
    
    private func makePlayer() -> AVQueuePlayer {
        let player = AVQueuePlayer(items: songs)
        player.actionAtItemEnd = .advance
        player.addObserver(self, forKeyPath: "currentItem", options: [.new, .initial] , context: nil)
        return player
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem", let player = object as? AVPlayer,
            let currentItem = player.currentItem?.asset as? AVURLAsset {
            // songLabel.text = currentItem.urlh.lastPathComponent
        }
    }
    
    func playAudio() {
        player.play()
    }
    
    func pauseAudio() {
        player.pause()
    }
    
}
