//
//  InterfaceController.swift
//  HeartRate WatchKit Extension
//
//  Created by 西澤健将 on 2020/04/27.
//  Copyright © 2020 西澤健将. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {
    
    var hkWorkoutSession: HKWorkoutSession?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
        
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBOutlet weak var LatestHeart: WKInterfaceLabel!
    var heartRateLatest: Double = 0.0 {
        didSet {
            if self.heartRateLatest < 0.0 {
                LatestHeart.setText("最新 : ----")
            } else {
                LatestHeart.setText("最新 : \(self.heartRateLatest)")
            }
        }
    }

    @IBOutlet weak var AverageHeart: WKInterfaceLabel!
    var heartRateAverage: Double = 0.0 {
        didSet {
            if self.heartRateAverage < 0.0 {
                AverageHeart.setText("平均 : ----")
            } else {
                AverageHeart.setText("平均 : \(self.heartRateAverage)")
            }
        }
    }

    @IBOutlet weak var MaxHeart: WKInterfaceLabel!
    var heartRateMax: Double = 0.0 {
        didSet {
            if self.heartRateMax < 0.0 {
                MaxHeart.setText("最大 : ----")
            } else {
                MaxHeart.setText("最大 : \(self.heartRateMax)")
            }
        }
    }

    @IBOutlet weak var MinHeart: WKInterfaceLabel!
    var heartRateMin: Double = 0.0 {
        didSet {
            if self.heartRateMin < 0.0 {
                MinHeart.setText("最小 : ----")
            } else {
                MinHeart.setText("最小 : \(self.heartRateMin)")
            }
        }
    }
    @IBOutlet weak var CountHeart: WKInterfaceLabel!
    var heartRateCount: Double = 0.0 {
        didSet {
            if self.heartRateCount < 0.0 {
                CountHeart.setText("回数 : ----")
            } else {
                CountHeart.setText("回数 : \(self.heartRateCount)")
            }
        }
    }

    var dateWorkoutSessionStart: Date?
    var dateWorkoutSessionEnd: Date?

    // Workout状態設定スイッチ操作時の処理ハンドラ
    @IBAction func WorkoutManager(_ value: Bool) {
        if (value) {
            // WorkoutSession開始
            self.startWorkoutSession()
            self.dateWorkoutSessionStart = Date()
            self.dateWorkoutSessionEnd = nil
            self.heartRateAverage = -1.0
            self.heartRateMax = -1.0
            self.heartRateMin = -1.0
            self.heartRateCount = -1.0
        } else {
            // WorkoutSession終了
            self.stopWorkoutSession()
            self.dateWorkoutSessionEnd = Date()
        }
    }
    
    // HealthKit 関連データ
    let hkStore = HKHealthStore()
    var hkIsAuthorized = false
    let hkTypeHeartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!

    // 定周期処理
    var timerReadHK: Timer?
    let timerIntervalReadHK = 5.0

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
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
            
            // HealthKit定周期読み出し開始
            self.startReadHK()
        }
    }

    // HealthKit データ読み出しの開始
    func startReadHK() {
        self.timerReadHK = Timer.scheduledTimer(timeInterval: self.timerIntervalReadHK, target: self, selector: #selector(self.updateHeartRateNormal), userInfo: nil, repeats: true)
    }
    
    let hkUnitHeartRate = HKUnit(from: "count/min")
    
   // 通常時の心拍数情報更新処理
   @objc func updateHeartRateNormal() {
       if self.hkIsAuthorized {
           let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
           let query = HKSampleQuery(sampleType: self.hkTypeHeartRate, predicate: nil, limit: 1, sortDescriptors: sortDescriptors, resultsHandler: { (query, samples, error) -> Void in
               if let error = error {
                   NSLog("[updateHeartRateNormal] resultHandler error: \(error.localizedDescription)")
               } else if let samples = samples {
                   let sample = samples[0] as! HKQuantitySample
                   NSLog("[updateHeartRateNormal] resultHandler sample: \(sample.debugDescription)")
                   let value = sample.quantity.doubleValue(for: self.hkUnitHeartRate)
                   DispatchQueue.main.async {
                       self.heartRateLatest = value
                   }
               }
           } )
           self.hkStore.execute(query)
       }
   }
    
    // WorkoutSession時の心拍数情報更新処理
   func updateHeartRateWO(start: Date, end: Date) {
       if self.hkIsAuthorized {
           let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
           let query = HKSampleQuery(sampleType: self.hkTypeHeartRate, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: {(query, samples, error) -> Void in
               if let error = error {
                   NSLog("[updateHeartRateWO] resultHandler error: \(error.localizedDescription)")
               } else if let samples = samples {
                   // 値取り出し
                   let values = samples.map{ ($0 as! HKQuantitySample).quantity.doubleValue(for: self.hkUnitHeartRate) }
                   NSLog("[updateHeartRateWO] resultHandler values: \(values)")

                    // 回数取得
                    let count = Double(values.count)
                    self.heartRateCount = count
                    NSLog("[updateHeartRateWO] resultHandler Count value:\(count)")

                   // 平均値取得
                   let total = values.reduce(0, +)
                   let average = total / Double(values.count)
                   self.heartRateAverage = average
                   NSLog("[updateHeartRateWO] resultHandler Average value:\(average)")

                   // 最大値取得
                   if let max = values.max() {
                       self.heartRateMax = max
                       NSLog("[updateHeartRateWO] resultHandler Max value:\(max)")
                   }
                   
                   // 最小値取得
                   if let min = values.min() {
                       self.heartRateMin = min
                       NSLog("[updateHeartRateWO] resultHandler Min value:\(min)")
                   }
               }
           })
           self.hkStore.execute(query)
       }
   }
        
}

// Workout Session 用の拡張定義
extension InterfaceController: HKWorkoutSessionDelegate {
    // WorkoutSession開始処理
    func startWorkoutSession() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        
        do {
            let session = try HKWorkoutSession(healthStore: self.hkStore, configuration: config)
            session.delegate = self
            self.hkWorkoutSession = session
            
            session.startActivity(with: nil)
        } catch let e as NSError {
            fatalError("*** Unable to create the workout session: \(e.localizedDescription) ***")
        }
    }
    
    // WorkoutSession終了処理
    func stopWorkoutSession() {
        guard let workoutSession = self.hkWorkoutSession else { return }
        workoutSession.stopActivity(with: nil)
    }
    
    // 状態変化検出時処理
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        NSLog("workoutSession delegate didChangeTo")
        switch toState {
        case .running:
            NSLog("Session status to running")
        case .stopped:
            NSLog("Session status to stopped")
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.hkWorkoutSession = nil
                guard let startDate = self.dateWorkoutSessionStart else { return }
                guard let endDate = self.dateWorkoutSessionEnd else { return }
                self.updateHeartRateWO(start: startDate, end: endDate)
            }
        default:
            NSLog("Other status \(toState.rawValue)")
        }
    }
    
    // エラー発生時処理
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        NSLog("workoutSession delegate didFailWithError \(error.localizedDescription)")
    }
}
