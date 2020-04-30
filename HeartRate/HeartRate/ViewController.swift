//
//  ViewController.swift
//  HeartRate
//
//  Created by 西澤健将 on 2020/04/27.
//  Copyright © 2020 西澤健将. All rights reserved.
//

import UIKit
import HealthKit
import Foundation
import WatchConnectivity

var globalHeartRateLatest = 0.0
var globalHeartRateBefore = 0.0
var globalData = "0"

class ViewController: UIViewController{
    
    // HealthKit 関連データ
    let hkStore = HKHealthStore()
    var hkIsAuthorized = false
    let hkTypeHeartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!

    // 定周期処理
    var timerReadHK: Timer?
    let timerIntervalReadHK = 5.0

    override func viewDidLoad() {
        // This method is called when watch view controller is about to be visible to user
        super.viewDidLoad()
        
        // HealthKit関連初期化処理
        //   ※HealthKit を使用できる場合のみ表示する
        if (HKHealthStore.isHealthDataAvailable()) {
            // HealthKit の使用許可ダイアログの表示
            let readTypes: Set<HKObjectType> = [self.hkTypeHeartRate]
            self.hkStore.requestAuthorization(toShare: nil, read: readTypes, completion: {(success, error) -> Void in
                if success {
                    NSLog("HealthKit Request Authorization succeeded")
                    self.hkIsAuthorized = true
                } else if let error = error {
                    NSLog("HealthKit Request Authorization error \(error)")
                } else {
                    NSLog("HealthKit Request Authorization error")
                }
            })
            
        }
        
        self.startReadHK()
        
    }
    
    func startReadHK() {
        self.timerReadHK = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateHK), userInfo: nil, repeats: true)
    }
    
    @objc func updateHK(){
        let object1 = globalData
        let object2 = globalHeartRateLatest
        let object3 = globalHeartRateBefore
        self.Receivedata1 = object1
        self.Receivedata2 = object2
        self.Receivedata3 = object3
    }

    @IBOutlet weak var receivedata1: UILabel!
    var Receivedata1: String = "0" {
        didSet {
            if self.Receivedata1 == "0" {
                receivedata1.text = "計測日時 : ----"
            } else {
                receivedata1.text = "計測日時 : \(self.Receivedata1)"
            }
        }
    }

    @IBOutlet weak var receivedata2: UILabel!
    var Receivedata2: Double = 0.0 {
        didSet {
            if self.Receivedata2 == 0.0 {
                receivedata2.text = "最新心拍数 : ----"
            } else {
                receivedata2.text = "最新心拍数 : \(self.Receivedata2)"
            }
        }
    }
    
    @IBOutlet weak var receivedata3: UILabel!
    var Receivedata3: Double = 0.0 {
        didSet {
            if self.Receivedata3 == 0.0 {
                receivedata3.text = "直近心拍数 : ----"
            } else {
                receivedata3.text = "直近心拍数 : \(self.Receivedata3)"
            }
        }
    }

    @IBAction func DemoTrigger(_ sender: Any) {
        let object1 = globalData
        let object2 = globalHeartRateLatest
        let object3 = globalHeartRateBefore
        self.Receivedata1 = object1
        self.Receivedata2 = object2
        self.Receivedata3 = object3

    }
    @IBAction func DemoReset(_ sender: Any) {
        let object1 = "0"
        let object2 = 0.0
        let object3 = 0.0
        self.Receivedata1 = object1
        self.Receivedata2 = object2
        self.Receivedata3 = object3
    }
}

class SessionHandler : NSObject, WCSessionDelegate{
    
    static let shared = SessionHandler()
    
    private var session = WCSession.default
    
    override init(){
        super.init()
        
        if isSuported(){
            session.delegate = self
            session.activate()
        }
        
        print("isPaired? \(session.isPaired), isWatchAppInstalled?: \(session.isWatchAppInstalled)")
    }
    
    func isSuported() -> Bool{
        return WCSession.isSupported()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive:\(session)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate:\(session)")
        self.session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any],replyHandler:@escaping([String:Any]) -> Void) {
        if message["request"] as? String == "version"{
            replyHandler(["version":"\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "No version")"])
        }
        let object1 = message["Data"] as? String
        let object2 = message["HeartRateLatest"] as? String
        let object3 = message["HeartRateBefore"] as? String
        
        if object1 != nil{
            globalData = String(object1!)
            print(globalData)
        }
        if object2 != nil{
            globalHeartRateLatest = atof(object2!)
            print(globalHeartRateLatest)
        }
        if object3 != nil{
            globalHeartRateBefore = atof(object3!)
            print(globalHeartRateBefore)
        }

    }
    
}
