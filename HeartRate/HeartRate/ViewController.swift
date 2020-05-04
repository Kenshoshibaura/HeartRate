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

//グローバル変数群 宣言
var globalHeartRateLatest = 0
var globalHeartRateBefore = 0
var globalHeartRateCount = 0
var globalHeartRateSum = 0
var globalData = "0"
var globalReceiveStatus = "未通信"
var globalSendStatus = "未実装"
var globalReceiveStartTime = Date()
var globalReceiveLastSuccessTime = Date()
var globalSendStartTime = Date()
var globalSendLastSuccessTime = Date()
var globalSendStartJudge = 0


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

        //定数域 文字色宣言
        LatestTitle.textColor = UIColor.white
        ChangeTitle.textColor = UIColor.white
        AverageTitle.textColor = UIColor.white
        MaxTitle.textColor = UIColor.white
        MinTitle.textColor = UIColor.white
        CountTitle.textColor = UIColor.white
        ReceiveTitle.textColor = UIColor.white
        ReceiveTimeTitle.textColor = UIColor.white
        ReceiveTimeMaxTitle.textColor = UIColor.white
        SendTitle.textColor = UIColor.gray
        SendTimeTitle.textColor = UIColor.gray
        SendTimeMaxTitle.textColor = UIColor.gray

        //変数域 文字色宣言
        LatestView.textColor = UIColor.white
        ChangeView.textColor = UIColor.white
        AverageView.textColor = UIColor.white
        MaxView.textColor = UIColor.white
        MinView.textColor = UIColor.white
        CountView.textColor = UIColor.white
        ReceiveView.textColor = UIColor.white
        ReceiveTimeView.textColor = UIColor.white
        ReceiveTimeMaxView.textColor = UIColor.white
        SendView.textColor = UIColor.gray
        SendTimeView.textColor = UIColor.gray
        SendTimeMaxView.textColor = UIColor.gray

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
        globalSendStartJudge = 1
        
    }
    
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    override func viewWillDisappear(_ animated: Bool){
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func startReadHK() {
        self.timerReadHK = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateHK), userInfo: nil, repeats: true)
    }
    
    @objc func updateHK(){
        self.ReceiveValue = globalReceiveStatus
        self.LatestValue = globalHeartRateLatest
        self.ChangeValue = globalHeartRateLatest - globalHeartRateBefore
        
        if globalHeartRateLatest > self.MaxValue {
            self.MaxValue = globalHeartRateLatest
        }
        if globalHeartRateCount != 0 {
            self.AverageValue = globalHeartRateSum / globalHeartRateCount
        }
        if (globalHeartRateLatest < self.MinValue) && (globalHeartRateLatest != 0) {
            self.MinValue = globalHeartRateLatest
        }
        self.CountValue = globalHeartRateCount
        
        let SuccessSpan = Date().timeIntervalSince(globalReceiveLastSuccessTime)
        if SuccessSpan > 20.0{
            self.ReceiveValue = "未通信"
            globalReceiveStatus = "未通信"
            self.ReceiveTimeValue = 0//
        }else{
            self.ReceiveValue = globalReceiveStatus
        }
        if ReceiveValue == "成功"{
            self.ReceiveTimeValue = Int(Date().timeIntervalSince(globalReceiveStartTime))
        }
        if self.ReceiveTimeValue > self.ReceiveTimeMaxValue{
            self.ReceiveTimeMaxValue = self.ReceiveTimeValue
        }
        globalSendStartJudge = 1

    }
    
    @IBOutlet weak var LatestTitle: UILabel!
    @IBOutlet weak var LatestView: UILabel!
    var LatestValue: Int = 0 {
        didSet {
            if self.LatestValue == 0 {
                LatestView.text = "000"
            } else {
                LatestView.text = "\(self.LatestValue)"
            }
        }
    }

    @IBOutlet weak var ChangeTitle: UILabel!
    @IBOutlet weak var ChangeView: UILabel!
    var ChangeValue: Int = 0 {
        didSet {
            if self.ChangeValue == 0 {
                ChangeView.text = "±0"
            } else if self.ChangeValue > 0{
                ChangeView.text = "+\(self.ChangeValue)"
            } else {
                ChangeView.text = "\(self.ChangeValue)"
            }
        }
    }

    @IBOutlet weak var MaxTitle: UILabel!
    @IBOutlet weak var MaxView: UILabel!
    var MaxValue: Int = 0 {
        didSet {
            if self.MaxValue == 0 {
                MaxView.text = "000"
            } else {
                MaxView.text = "\(self.MaxValue)"
            }
        }
    }

    @IBOutlet weak var AverageTitle: UILabel!
    @IBOutlet weak var AverageView: UILabel!
    var AverageValue: Int = 0 {
        didSet {
            if self.AverageValue == 0 {
                AverageView.text = "000"
            } else {
                AverageView.text = "\(self.AverageValue)"
            }
        }
    }

    @IBOutlet weak var MinTitle: UILabel!
    @IBOutlet weak var MinView: UILabel!
    var MinValue: Int = 300 {
        didSet {
            if self.MinValue == 300 {
                MinView.text = "000"
            } else {
                MinView.text = "\(self.MinValue)"
            }
        }
    }
    @IBOutlet weak var CountTitle: UILabel!
    @IBOutlet weak var CountView: UILabel!
    var CountValue: Int = 0 {
        didSet {
            if self.CountValue == 0 {
                CountView.text = "000"
            } else {
                CountView.text = "\(self.CountValue)"
            }
        }
    }

    @IBOutlet weak var ReceiveTitle: UILabel!
    @IBOutlet weak var ReceiveView: UILabel!
    var ReceiveValue: String = "未通信" {
        didSet {
            if self.ReceiveValue == "未通信" {
                ReceiveView.text = "未通信"
            } else {
                ReceiveView.text = "\(self.ReceiveValue)"
            }
        }
    }
    @IBOutlet weak var ReceiveTimeTitle: UILabel!
    @IBOutlet weak var ReceiveTimeView: UILabel!
    var ReceiveTimeValue: Int = 0 {
        didSet {
            if self.ReceiveTimeValue == 0 {
                ReceiveTimeView.text = "000秒"
            } else {
                ReceiveTimeView.text = "\(self.ReceiveTimeValue)秒"
            }
        }
    }
    @IBOutlet weak var ReceiveTimeMaxTitle: UILabel!
    @IBOutlet weak var ReceiveTimeMaxView: UILabel!
    var ReceiveTimeMaxValue: Int = 0 {
        didSet {
            if self.ReceiveTimeMaxValue == 0 {
                ReceiveTimeMaxView.text = "000秒"
            } else {
                ReceiveTimeMaxView.text = "\(self.ReceiveTimeMaxValue)秒"
            }
        }
    }
    @IBOutlet weak var SendTitle: UILabel!
    @IBOutlet weak var SendView: UILabel!
    var SendValue: String = "未実装" {
        didSet {
            if self.SendValue == "未実装" {
                SendView.text = "未実装"
            } else {
                SendView.text = "\(self.SendValue)"
            }
        }
    }
    @IBOutlet weak var SendTimeTitle: UILabel!
    @IBOutlet weak var SendTimeView: UILabel!
    var SendTimeValue: Int = 0 {
        didSet {
            if self.SendTimeValue == 0 {
                SendTimeView.text = "000秒"
            } else {
                SendTimeView.text = "\(self.SendTimeValue)秒"
            }
        }
    }
    @IBOutlet weak var SendTimeMaxTitle: UILabel!
    @IBOutlet weak var SendTimeMaxView: UILabel!
    var SendTimeMaxValue: Int = 0 {
        didSet {
            if self.SendTimeMaxValue == 0 {
                SendTimeMaxView.text = "000秒"
            } else {
                SendTimeMaxView.text = "\(self.SendTimeMaxValue)秒"
            }
        }
    }

    
    @IBAction func DataReset(_ sender: Any) {
        globalHeartRateLatest = 0
        globalHeartRateBefore = 0
        globalHeartRateCount = 0
        globalHeartRateSum = 0
        globalReceiveStatus = "未通信"
        globalSendStatus = "未通信"
        globalReceiveStartTime = Date()
        globalReceiveLastSuccessTime = Date()
        globalSendStartTime = Date()
        globalSendLastSuccessTime = Date()
        self.LatestValue = 0
        self.ChangeValue = 0
        self.MaxValue = 0
        self.AverageValue = 0
        self.MinValue = 300
        self.CountValue = 0
        self.ReceiveValue = "未通信"
        self.ReceiveTimeValue = 0
        self.ReceiveTimeMaxValue = 0
        self.SendValue = "未実装"
        self.SendTimeValue = 0
        self.SendTimeMaxValue = 0
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
        //globalReceiveStatus = "通信中"
        if message["request"] as? String == "version"{
            replyHandler(["version":"\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "No version")"])
        }
        let object1 = message["Data"] as? String
        let object2 = message["HeartRateLatest"] as? String
        let object3 = message["HeartRateBefore"] as? String
        
        if object1 != nil{
            globalData = String(object1!)
            //print(globalData)
        }
        if object2 != nil{
            globalHeartRateLatest = Int(atof(object2!))
            //print(globalHeartRateLatest)
        }
        if object3 != nil{
            globalHeartRateBefore = Int(atof(object3!))
            //print(globalHeartRateBefore)
        }
        globalHeartRateCount += 1
        globalHeartRateSum += globalHeartRateLatest
        if (globalReceiveStatus != "成功"){
            globalReceiveStartTime = Date()
        }
        globalReceiveLastSuccessTime = Date()
        globalReceiveStatus = "成功"
        
        if globalSendStartJudge == 1{
            //startSendMessage()
            SendMessageForWatch()
            globalSendStartJudge = 0
        }

    }
    func isReachable() -> Bool{
        return session.isReachable
    }
    @objc func SendMessageForWatch(){
        //print("Sending...")
        let message = ["Data":String(globalHeartRateCount)]
        //let message = ["Data":String(now),"HeartRateLatest":String(value)]
        DispatchQueue.main.async {
            if self.isReachable(){
                //print("Reachable")
                self.session.sendMessage(message, replyHandler: { replyDict in print(replyDict)},errorHandler: { error in print(error.localizedDescription)})
            }else{
                print("iPhone is not reachable!!")
            }
        }
    }
    /*
    var timerSendHK: Timer?
    
    @objc func startSendMessage() {
        print("Send Started")
        self.timerSendHK = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.SendMessageForWatch), userInfo: nil, repeats: true)
    }
    */
}
