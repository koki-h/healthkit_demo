//
//  ViewController.swift
//  healthkit_demo
//
//  Created by koki on 2018/12/03.
//  Copyright © 2018 koki. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    @IBOutlet weak var tfBodyTemperature: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        findAllBodyTemperature()
    }
    
    @IBAction func btnSave(_ sender: Any) {
        saveBodyTemperature()
    }
    
    /**
     引数に渡された文字列を指定のデータへ変換してHealthStoreへ永続化します。
     渡される文字列は、Double型へキャスト出来る形式である必要があります。
     
     :param: unit       健康情報の単位型
     :param: type       健康情報のデータ型
     :param: valueStr   データ文字列
     :param: completion 永続化処理完了時に実行される処理
     */
    func saveHealthValueWithUnit(unit: HKUnit! , type: HKQuantityType!, valueStr: String!, completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        // 保存領域オブジェクトをインスタンス化します。
        let healthStore: HKHealthStore = HKHealthStore()
        
        // 数値オブジェクトを生成します。単位と値が入ります。
        let quantity: HKQuantity = HKQuantity(unit: unit, doubleValue: Double(valueStr) ?? 0)
        
        // HKObjectのサブクラスである、HKQuantitySampleオブジェクトを生成します。
        // 計測の開始時刻と終了時刻が同じ場合は同じ値を設定します。
        let sample: HKQuantitySample = HKQuantitySample(type: type, quantity: quantity, start: Date(), end: Date())
        
        // 健康情報のデータ型を保持したNSSetオブジェクトを生成します。
        // 永続化したい情報が複数ある場合はobjectに複数のデータ型配列を設定します。
        let types: NSSet! = NSSet(object: type)
        
        let authStatus:HKAuthorizationStatus = healthStore.authorizationStatus(for: type)
        
        if authStatus == .sharingAuthorized {
            healthStore.save(sample, withCompletion:completion )
        } else {
            
            // 体温型のデータをHealthStoreに永続化するために、ユーザーへ許可を求めます。
            // 許可されたデータのみ、アプリケーションからHealthStoreへ書き込みする権限が与えられます。
            // ヘルスケアの[ソース]タブ画面がモーダルで表示されます。
            // 第1引数に指定したNSSet!型のshareTypesの書き込み許可を求めます。
            // 第2引数に指定したNSSet!型のreadTypesの読み込み許可を求めます。
            
            healthStore.requestAuthorization(toShare: types as? Set<HKSampleType>, read: nil) {
                success, error in
                
                if error != nil {
                    NSLog(error.debugDescription);
                    return
                }
                
                if success {
                    NSLog("保存可能");
                    healthStore.save(sample, withCompletion:completion)
                }
            }
        }
    }
    
    func saveBodyTemperature() {
        let textStr: String! = String(format:"\(tfBodyTemperature.text ?? "0")")
        // 体温の単位を生成します。単位は℃（摂氏）です。
        let btUnit: HKUnit! = HKUnit.degreeCelsius()
        // 体温情報の型を生成します。
        let btType: HKQuantityType! = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyTemperature)
        
        // 永続化処理完了時に非同期で呼び出されます。
        saveHealthValueWithUnit(unit: btUnit, type: btType, valueStr: textStr, completion: {
            success, error in
            
            if error != nil {
                NSLog(error!.localizedDescription)
                return
            }
            
            if success {
                NSLog("体温データの永続化に成功しました。")
                self.findAllBodyTemperature()
            }
        })
    }
    
    /**
     HealthStoreから引数に渡されたデータ型に一致する健康情報を全件取得します。
     
     :param: unit       健康情報の単位型
     :param: type       取得したいデータ型
     :param: completion 取得完了時に実行される処理
     */
    func findAllHealthValueWithUnit(unit: HKUnit!, type: HKQuantityType!, completion: @escaping ((_ query: HKSampleQuery?, _ responseObj: [AnyObject]?, _ error: Error?) -> Void)) {
        let healthStore = HKHealthStore()
        
        // HealthStoreのデータを全件取得するHKSampleQueryを返却します。
        let findAllQuery : () -> HKSampleQuery = {
            return HKSampleQuery(sampleType: type, predicate: nil, limit: 0, sortDescriptors: nil, resultsHandler: completion)
        }
        
        let types: NSSet! = NSSet(object: type)
        
        let authStatus:HKAuthorizationStatus = healthStore.authorizationStatus(for: type)
        
        if authStatus == .sharingAuthorized {
            healthStore.execute(findAllQuery())
        } else {
            
            // 体温型のデータをHealthStoreから取得するために、ユーザーへ許可を求めます。
            // 許可されたデータのみ、アプリケーションからHealthStoreへ読み込みする権限が与えられます。
            // ヘルスケアの[ソース]タブ画面がモーダルで表示されます。
            // 第1引数に指定したNSSet!型のshareTypesの書き込み許可を求めます。
            // 第2引数に指定したNSSet!型のreadTypesの読み込み許可を求めます。
            
            healthStore.requestAuthorization(toShare: nil, read: types as? Set<HKObjectType>) {
                success, error in
                
                if error != nil {
                    NSLog(error.debugDescription);
                    return
                }
                
                if success {
                    NSLog("取得可能");
                    // 引数に指定されたクエリーを実行します
                    healthStore.execute(findAllQuery())
                }
            }
        }
    }
    
    func findAllBodyTemperature() {
        // 体温の単位を生成します。単位は℃（摂氏）です。
        let btUnit: HKUnit! = HKUnit.degreeCelsius()
        // 体温情報の型を生成します。
        let btType: HKQuantityType! = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyTemperature)
        
        // 取得処理完了時に非同期で呼び出されます。
        findAllHealthValueWithUnit(unit: btUnit, type: btType , completion: {
            query, responseObj, error in
            
            if error != nil {
                NSLog(error.debugDescription)
                return
            }
            
            // 取得した結果がresponseObjに格納されています。
            // アプリケーションで使用する場合、[AnyObject]!型のresponseObjを必要な型にキャストする必要があります。
            NSLog("resultObj : \(String(describing: responseObj))")
            
            let btUnit: HKUnit = HKUnit.degreeCelsius()
            
            var btResults: [Double?] = []
            
            // HealthStoreで使用していた型から体温の値へと復元します。
            for bodyTemperature: HKQuantitySample in responseObj as! [HKQuantitySample] {
                // 値を取得します。
                let btQuantity: HKQuantity! = bodyTemperature.quantity
                let btResult: Double = btQuantity.doubleValue(for: btUnit)
                btResults.append(btResult);
            }
            NSLog("values : \(btResults)")
        })
    }
}

