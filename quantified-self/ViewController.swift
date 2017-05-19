//
//  ViewController.swift
//  quantified-self
//
//  Created by Austin Wood on 5/19/17.
//  Copyright © 2017 Austin Wood. All rights reserved.
//

import UIKit
import Just

// https://github.com/JustHTTP/Just

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func submitPressed(_ sender: Any) {
        Just.get("https://austinbio.herokuapp.com/api/users") { (r) in
            print(r)
            print(r.json ?? "No JSON")
            print("")
        }
        
//        let heartRate = Int(textField.text!)!
//        let data = ["heartrate": 2]
        Just.patch("https://austinbio.herokuapp.com/api/users/1") { (r) in
            print(r)
            print(r.json ?? "No JSON")
            print("")
        }
    }
    
}

