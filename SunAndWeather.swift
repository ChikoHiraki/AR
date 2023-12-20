//
//  SunAndWether.swift
//  AR_app
//
//  Created by 平木稚子 on 2023/12/13.
//

import UIKit
import SceneKit
import ARKit
import CoreGraphics
import Solar
import Foundation
import CoreLocation
import SwiftSoup

class SunAndWeather {
    
    // 度→ラジアンに変換
    func ToRadians(_ degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }

    // ラジアン→度に変換
    func ToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }

    
    func getSunData(month:Int,day:Int,hour:Int) ->  (h:Double, A:Double) {
        let daysInMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        var julian_day = day
        for m in 1..<month {
            julian_day += daysInMonth[m]
        }
        let J = Double(julian_day)
        let Om = 2 * Double.pi / 365
        let D = 0.33281 - 22.984 * cos(Om * J) - 0.34990 * cos(2 * Om * J) - 0.13980 * cos(3 * Om * J) + 3.7872 * sin(Om * J) + 0.03250 * sin(2 * Om * J) + 0.07187 * sin(3 * Om * J)
        // 均時差
        let e = 0.0072 * cos(Om * J) - 0.0528 * cos(2 * Om * J) - 0.0012 * cos(3 * Om * J) - 0.1229 * sin(Om * J) - 0.1565 * sin(2 * Om * J) - 0.0041 * sin(3 * Om * J)
        // 定数の定義
        let phi = 26.33440  // 緯度(°)
        let theta = 127.80551 // 経度(°)
        let delta = Double(-4 - 29/60 - 53/3600)  // 太陽赤緯(°)

        let T = Double(hour) + (theta - 135) / 15 + e
        let t = 15 * T - 180
    
        // 高度
        let h = ToDegrees((asin(sin(ToRadians(phi)) * sin(ToRadians(delta)) + cos(ToRadians(phi)) * cos(ToRadians(delta)) * cos(ToRadians(t)))))
        
        let sinA = ( cos(ToRadians(delta)) * sin(ToRadians(t)) / cos(ToRadians(h)) )
        let cosA = ((sin(ToRadians(h)) * sin(ToRadians(phi)) - sin(ToRadians(delta))) / cos(ToRadians(h)) / cos(ToRadians(phi)))
        // 方位角
        let A = ToDegrees((atan2(sinA, cosA) + Double.pi))
            
        //print("h,A = " + String(h) + " , " +  String(A))
        return (h, A)

    }
    
    func getDate() ->  (date:String, month:Int, day:Int, hour:Int, now_time:String) {
        // 現在の時刻を取得
        let date = Date()
        
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        let date_jp = f.string(from: date)
        print(date_jp)
        
        f.timeStyle = .none
        f.dateStyle = .short
        let ymd = f.string(from: date)
        
        let ymd2 = ymd.components(separatedBy: "/")
        let month = Int(ymd2[1])
        let day = Int(ymd2[2])
        
        f.timeStyle = .short
        f.dateStyle = .none
        let now_time = f.string(from: date)
        
        let now_time2 = now_time.components(separatedBy: ":")
        let hour = Int(now_time2[0])
        print("now_time = " + String(now_time))
        
        return (date_jp, month!, day!, hour!, now_time)
    }
    
    func getSunPosition(elevation:Double, azimuth:Double) ->  (x:Double, y:Double, z:Double) {
        // 太陽の仰角(elevation), 方位角(azimuth)

        let x = sin(ToRadians(180-azimuth))
        let z = cos(ToRadians(180-azimuth))
        let y = sin(ToRadians(elevation))
        
        return (x,y,z)
    }
    
    func getSunriseAndSunset() ->  (sunrise:String, sunset:String)  {
        // 日の出と日の入り
        let date = Date()
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.timeStyle = .short
        f.dateStyle = .none
        
        let solar = Solar(for: date, coordinate: CLLocationCoordinate2D(latitude: 26.33440, longitude: 127.80551))
        let rise = solar?.sunrise
        let set = solar?.sunset
        
        let sunrise = f.string(from: rise!)
        let sunset = f.string(from: set!)
        return (sunrise,sunset)
    }
    
    func ToDecimal(timeString:String) -> Double {
        let components = timeString.components(separatedBy: ":")
        let hour = Int(components[0])
        let minute = Int(components[1])
        let decimalTime = Double(hour!) + Double(minute!) / 60.0
        
        return decimalTime
    }
    
    func getPlaneEmissionTime(now_time:String) -> Int {
        let nowtime = ToDecimal(timeString: now_time)
        let sun = getSunriseAndSunset()
        let sunrise = ToDecimal(timeString: sun.sunrise)
        let sunset = ToDecimal(timeString: sun.sunset)
        
        var emissionTime = 0
        
        if sunrise < nowtime, nowtime < sunset {
            let timeIntervals: [Double] = [10.0, 12.0, 14.0, 16.0]
            
            for time in timeIntervals {
                if nowtime < time {
                    emissionTime = Int(time - 1)
                    break
                }
            }
            if emissionTime == 0 {
                emissionTime = 17
            }
        }
        
        print("emissionTime = " + String(emissionTime))
        return emissionTime
    }
    
    /**
    func loadImage (weather_folder:String, img_name:String) -> UIImage? {
        // テクスチャを読み込む
        let imageURLString = "https://ie.u-ryukyu.ac.jp/~e205735/texture/\(weather_folder)/\(img_name).png"
        // URLを作成
        if let imageURL = URL(string: imageURLString), let imageData = try? Data(contentsOf: imageURL) {
            // DataからUIImageを生成
            let texture = UIImage(data: imageData)
            return texture
        }
        return nil
        
    }
     */
    
    func loadImage(weather_folder: String, img_name: String, completion: @escaping (UIImage?) -> Void) {
        let imageURLString = "https://ie.u-ryukyu.ac.jp/~e205735/texture/\(weather_folder)/\(img_name).png"

        // バックグラウンドキューで非同期に処理
        DispatchQueue.global().async {
            if let imageURL = URL(string: imageURLString), let imageData = try? Data(contentsOf: imageURL) {
                // メインキューで UI 更新を行う
                DispatchQueue.main.async {
                    // Data から UIImage を生成
                    let texture = UIImage(data: imageData)
                    completion(texture)
                }
            } else {
                // 読み込みに失敗した場合もメインキューで UI 更新を行う
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    
    /**
    func scrapeWeather(hour:Int) -> String {
        // URLを指定
        let e = "error"
        let urlString = "https://tenki.jp/forecast/10/50/9110/47205/1hour.html"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return e
        }
        do {
            // ダウンロードしたデータを文字列に変換
            let htmlString = try String(contentsOf: url, encoding: .utf8)
            let doc = try SwiftSoup.parse(htmlString)

            // idがforecast-point-1h-todayの要素を取得
            guard let forecastPoint1hToday = try doc.select("#forecast-point-1h-today").first() else {
                print("Element with id 'forecast-point-1h-today' not found")
                return e
            }
            
            // classがweatherの要素を取得
            guard let weatherList = try forecastPoint1hToday.select(".weather").first() else {
                print("Element with class 'weather' not found")
                return e
            }
            
            /**
            guard let weather_hour = try? weatherList.select(".past").get(hour) else {
                print("Element with class 'weatherList' not found")
                return e
            }
            */

            // 要素のテキストを取得
            //let weatherText = try weather_hour.text()
            let weatherText = try weatherList.text()
            
            let stringArray = weatherText.components(separatedBy: " ")
            let now_weather = stringArray[hour]
            
            return now_weather
 
        } catch {
            print("Error: \(error.localizedDescription)")
            return e
        }
    }
     */
    
    func scrapeWeather(hour: Int, completion: @escaping (String?) -> Void) {
        let e = "error"
        let urlString = "https://tenki.jp/forecast/10/50/9110/47205/1hour.html"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(e)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(e)
                return
            }

            if let data = data, let htmlString = String(data: data, encoding: .utf8) {
                do {
                    let doc = try SwiftSoup.parse(htmlString)

                    guard let forecastPoint1hToday = try doc.select("#forecast-point-1h-today").first() else {
                        print("Element with id 'forecast-point-1h-today' not found")
                        completion(e)
                        return
                    }

                    guard let weatherList = try forecastPoint1hToday.select(".weather").first() else {
                        print("Element with class 'weather' not found")
                        completion(e)
                        return
                    }

                    let weatherText = try weatherList.text()
                    let stringArray = weatherText.components(separatedBy: " ")
                    let now_weather = stringArray[hour]

                    completion(now_weather)
                } catch {
                    print("Error: \(error.localizedDescription)")
                    completion(e)
                }
            }
        }

        task.resume()
    }

}
