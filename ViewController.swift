//
//  ViewController.swift
//  AR_app
//
//  Created by 平木稚子 on 2023/12/13.

import UIKit
import SceneKit
import ARKit
import CoreGraphics
import Solar
import Foundation
import CoreLocation
import SwiftSoup

class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate{

    @IBOutlet var sceneView: ARSCNView!
    
    let sunAndWeather = SunAndWeather()
    var date: (date: String, month: Int, day: Int, hour: Int, now_time: String)?
    var weather: String?
    var house_emission: UIImage?
    var plane_emission: UIImage?
    
    var isPlaneDetected = false
    
    var locationManager: CLLocationManager!
    var currentHeading: CLLocationDirection?
    var objectNode: SCNNode?
    // デバイスアングルを保持するプロパティ
    var heading: CLLocationDirection = 0.0
    
    var lightInfoLabel = UILabel(frame: CGRect(x: 20, y: 30, width: 170, height: 25))
    var lightInfoLabel2 = UILabel(frame: CGRect(x: 20, y: 55, width: 170, height: 25))
    var groundEmissionLabel = UILabel(frame: CGRect(x: 20, y: 80, width: 170, height: 25))
    var houseEmissionLabel = UILabel(frame: CGRect(x: 20, y: 105, width: 170, height: 25))
    var deviceAngleLabel = UILabel(frame: CGRect(x: 20, y: 130, width: 170, height: 25))
    
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        //画像読み込み
        
        date = sunAndWeather.getDate()
        //weather = sunAndWeather.scrapeWeather(hour:date!.hour)
        let semaphore = DispatchSemaphore(value: 0)
        // 非同期関数の呼び出し
        sunAndWeather.scrapeWeather(hour: date!.hour) { [weak self] (result) in
            // コールバック内で結果の処理を行う
            if let result = result {
                // 結果が正常な場合の処理
                self?.weather = result
                // 他の処理を続ける
            } else {
                // エラーが発生した場合の処理
                print("Error scraping weather.")
            }
            // 非同期処理が完了したことをセマフォに通知
            semaphore.signal()
        }

        // 非同期処理が完了するまで待機
        semaphore.wait()

        // ここから先のコードは非同期処理が完了した後に実行される

        //weather = "曇り"
        DispatchQueue.main.async {
            self.deviceAngleLabel.text = "天気：\(self.weather!)"
        }
        var weather_folder = "sun"
        if weather == "曇り" {
            weather_folder = "cloud"
        }
        //house_emission = sunAndWeather.loadImage(weather_folder: weather_folder, img_name: "house_emission")
        // 非同期関数の呼び出し
        sunAndWeather.loadImage(weather_folder: weather_folder, img_name: "house_emission") { [weak self] (image) in
            // コールバック内で画像の取得が完了した後の処理を行う
            if let image = image {
                // 画像の取得に成功した場合の処理
                self?.house_emission = image
                // 画像の取得に成功した場合の処理
                DispatchQueue.main.async {
                    // メインスレッドで UI 更新を行う
                    // 家のモデルを選択
                    let scene = self!.sceneView.scene
                    if let houseNode = scene.rootNode.childNode(withName: "house_model", recursively: true) {
                        houseNode.enumerateChildNodes { (child, _) in
                            if let geometry = child.geometry {
                                for material in geometry.materials {
                                    material.emission.contents = self?.house_emission
                                }
                            }
                        }
                    }
                }
            } else {
                // 画像の取得に失敗した場合の処理
                print("Image loading failed.")
            }
        }
        
        //date?.now_time = "9:00"
        let planeEmissionTime = sunAndWeather.getPlaneEmissionTime(now_time: date!.now_time)
        //plane_emission = sunAndWeather.loadImage(weather_folder: weather_folder, img_name: "plane_emission_\(planeEmissionTime)")
        // 非同期関数の呼び出し
        sunAndWeather.loadImage(weather_folder: weather_folder, img_name: "plane_emission_\(planeEmissionTime)") { [weak self] (image) in
            // コールバック内で画像の取得が完了した後の処理を行う
            if let image = image {
                // 画像の取得に成功した場合の処理
                self?.plane_emission = image
                //平面を選択
                let scene = self!.sceneView.scene
                if let planeNode = scene.rootNode.childNode(withName: "plane_model", recursively: true) {
                    planeNode.enumerateChildNodes { (child, _) in
                        if let geometry = child.geometry {
                            for material in geometry.materials {
                                material.emission.contents = self?.plane_emission
                            }
                        }
                    }
                }
            } else {
                // 画像の取得に失敗した場合の処理
                print("Image loading failed.")
            }
        }
        
        
        
        
        sceneView.delegate = self
        //sceneView.showsStatistics = true
        
        let scene = SCNScene(named: "art.scnassets/house_scene.scn")!
        sceneView.scene = scene
        
        // デフォルトの照明を自動的に有効にしない
        sceneView.autoenablesDefaultLighting = false
        // 光源の位置や環境に応じて自動的に照明を更新しない
        sceneView.automaticallyUpdatesLighting = false
                
        // 位置情報マネージャのセットアップ
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        
        // ラベルの設定
        lightInfoLabel.text = "光源強度：0.0"
        lightInfoLabel.font = UIFont.systemFont(ofSize: 20)
        lightInfoLabel.backgroundColor =  UIColor.white
        self.view.addSubview(lightInfoLabel)
        lightInfoLabel2.text = "色温度：0.0"
        lightInfoLabel2.font = UIFont.systemFont(ofSize: 20)
        lightInfoLabel2.backgroundColor =  UIColor.white
        self.view.addSubview(lightInfoLabel2)
        groundEmissionLabel.text = "地面の放射：0.0"
        groundEmissionLabel.font = UIFont.systemFont(ofSize: 20)
        groundEmissionLabel.backgroundColor =  UIColor.white
        self.view.addSubview(groundEmissionLabel)
        houseEmissionLabel.text = "家の放射：0.0"
        houseEmissionLabel.font = UIFont.systemFont(ofSize: 20)
        houseEmissionLabel.backgroundColor =  UIColor.white
        self.view.addSubview(houseEmissionLabel)
        deviceAngleLabel.text = "天気：\(weather!)"
        deviceAngleLabel.font = UIFont.systemFont(ofSize: 20)
        deviceAngleLabel.backgroundColor =  UIColor.white
        self.view.addSubview(deviceAngleLabel)
        
    }
    
    // 方向の更新を検知するためのデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // trueHeadingプロパティを使用して、地理的北へのデバイスの角度を取得します
        heading = newHeading.trueHeading
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // 光源情報を有効にする
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    func colorFromTemperature(temperature: CGFloat) -> UIColor {
        // 色温度からカラー情報に変換する
        let temperature = temperature / 100.0
        var red, green, blue: CGFloat
        if temperature <= 66.0 {
            red = 255.0
            green = temperature
            green = 99.4708025861 * log(green) - 161.1195681661
            if temperature <= 19.0 {
                blue = 0.0
            } else {
                blue = temperature - 10.0
                blue = 138.5177312231 * log(blue) - 305.0447927307
            }
        } else {
            red = temperature - 60.0
            red = 329.698727446 * pow(red, -0.1332047592)
            green = temperature - 60.0
            green = 288.1221695283 * pow(green, -0.0755148492)
            blue = 255.0
        }
        red = min(max(red, 0), 255)
        green = min(max(green, 0), 255)
        blue = min(max(blue, 0), 255)
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
    }
    
    
    func createLight (x:Float, y:Float, z:Float, originNode:SCNNode, Intensity:Double, ColorTemperature:Double) -> SCNLight {
        // Lightの作成
        let dLight = SCNLight()
        dLight.type = .directional
        let dLightNode = SCNNode()
        dLightNode.light = dLight
        
        // ライトの位置と向きを設定
        dLightNode.position = SCNVector3(x: x, y: y, z: z)
        if weather == "曇り" {
            dLightNode.position = SCNVector3(x: x, y: y * 3, z: z)
        }
        let scene = sceneView.scene
        if let houseNode = scene.rootNode.childNode(withName: "house_model", recursively: true) {
            let constraint = SCNLookAtConstraint(target: houseNode)
            dLightNode.constraints = [constraint]
        }
        
        dLight.intensity = Intensity * 1.2 //強度を設定
        let lightColor = colorFromTemperature(temperature: ColorTemperature)
        dLight.color = lightColor
        DispatchQueue.main.async {
            self.lightInfoLabel.text = "光源強度：\(Int(Intensity))"
            self.lightInfoLabel2.text = "色温度：\(Int(ColorTemperature))"
        }
        
        // Shadowの設定
        dLight.shadowColor = UIColor(white: 0, alpha: 0.8)
        dLight.shadowMode = .deferred
        dLight.castsShadow = true
        dLight.forcesBackFaceCasters = true
        if weather == "曇り" {
            dLight.forcesBackFaceCasters = true
            dLight.intensity = Intensity * 0.7
            dLight.shadowColor = UIColor(white: 0, alpha: 0.7)
            dLight.shadowSampleCount = 200
            dLight.shadowRadius = 40
        }
        
        // ライトを平面の位置に追加
        dLight.categoryBitMask = 1
        originNode.addChildNode(dLightNode)
        
        return dLight
    }
    
    // 平面を検出したときに呼ばれる
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard !isPlaneDetected else {
            return
        }
        let scene = sceneView.scene
        let dAngle = heading
        print("deviceAngle = " + String(dAngle))
        
        //let sunData = sunAndWeather.getSunData(month:date!.month, day:date!.day, hour:date!.hour)
        let sunData = sunAndWeather.getSunData(month:date!.month, day:date!.day, hour:9)
        let sunPosition = sunAndWeather.getSunPosition(elevation: sunData.h, azimuth: sunData.A)
    
        //回転させるためのノード
        let originNode = SCNNode()
        sceneView.scene.rootNode.addChildNode(originNode)
        originNode.position = SCNVector3(0, 0, 0)
        
        // 光源情報、色情報を取得
        var ambientIntensity = 0.0
        var ambientColorTemperature = 0.0
        if let lightEstimation = sceneView.session.currentFrame?.lightEstimate {
            ambientIntensity = lightEstimation.ambientIntensity
            ambientColorTemperature = lightEstimation.ambientColorTemperature //色温度
        } else {
            ambientIntensity = 1000.0
            ambientColorTemperature = 6500.0
        }
        
        
        let dLight1 = createLight(x: Float(sunPosition.x), y: Float(sunPosition.y), z: Float(sunPosition.z), originNode: originNode, Intensity: ambientIntensity, ColorTemperature: ambientColorTemperature)


         
        
        // 家のモデルを表示
        if let houseNode = scene.rootNode.childNode(withName: "house_model", recursively: true) {
            houseNode.enumerateChildNodes { (child, _) in
                if let geometry = child.geometry {
                    for material in geometry.materials {
                        if let texture = UIImage(named: "art.scnassets/house_texture.png") {
                            // マテリアルのカラーにテクスチャを割り当て
                            material.diffuse.contents = texture
                        }
                        material.emission.contents = house_emission
                        material.emission.intensity = ambientIntensity / 800
                        if weather == "曇り" {
                            material.emission.intensity = ambientIntensity / 800
                        }
                        // ラベルに光源情報を表示
                        DispatchQueue.main.async {
                            self.houseEmissionLabel.text = "家の放射：\(round(material.emission.intensity * 10) / 10)"
                        }
                    }
                }
            }
            // 地面から1mm上に表示
            houseNode.position.y += Float(0.001)
            houseNode.categoryBitMask = 2
            originNode.addChildNode(houseNode)
            
        }
        
        //影を表示する平面
        let planeGeometry = SCNPlane(width: 5.0, height: 5.0)
        let shadowNode = SCNNode(geometry: planeGeometry)
        // 平面を水平に回転させる
        shadowNode.eulerAngles.x = -.pi / 2
        for material in planeGeometry.materials {
            // 色を0(黒)に設定
            material.diffuse.intensity = 0
            // 粗さを1に設定
            material.roughness.intensity = 1.0
            // ブレンドモードを変更
            material.blendMode = .subtract
        }
        //shadowNode.isHidden = true
        shadowNode.categoryBitMask = 1
        originNode.addChildNode(shadowNode)
        
        
        
        // 平面読み込み
        if let planeNode = scene.rootNode.childNode(withName: "plane_model", recursively: true) {
            planeNode.enumerateChildNodes { (child, _) in
                if let geometry = child.geometry {
                    for material in geometry.materials {
                        material.emission.contents = plane_emission
                        material.emission.intensity = ambientIntensity / 1500
                        if weather == "曇り" {
                            material.emission.intensity = ambientIntensity / 1500
                        }
                        // 色を0(黒)に設定
                        material.diffuse.intensity = 0
                        // 粗さを1に設定
                        material.roughness.intensity = 1.0
                        // ブレンドモードを変更
                        material.blendMode = .add
    
                        // ラベルに光源情報を表示
                        DispatchQueue.main.async {
                            self.groundEmissionLabel.text = "地面の放射：\(round(material.emission.intensity * 10) / 10)"
                        }
                         
                    }
                }
            }
            // 地面から1mm下に表示
            //planeNode.isHidden = true
            planeNode.categoryBitMask = 1
            planeNode.position.y -= Float(0.001)
            originNode.addChildNode(planeNode)
            
        }
        
        originNode.eulerAngles.y = Float(sunAndWeather.ToRadians(dAngle))
        node.addChildNode(originNode)
        
        // 平面が検出されたフラグを設定
        isPlaneDetected = true
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
