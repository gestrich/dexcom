//
//  EGV.swift
//  
//
//  Created by Bill Gestrich on 11/8/20.
//

import Foundation

struct EGV: Codable {
    let value: Int
    let systemTime: Date
    let displayTime: Date
    let realtimeValue: Int?
    let smoothedValue: Int?
    let trendRate: Float?
    let trendDescription: String
    
    var debugDescription: String {
        return "\(displayTime): \(value), (\(trendDescription) \(trendRate ?? 0.0))"
    }
    
    func simpleDescription() ->  String {
        return "\(value) (\(trendDescription) \(trendRate ?? 0.0))"
    }
    
    func displayDateDescription() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatterPrint.dateFormat = "h:mm a"
        return dateFormatterPrint.string(from: displayTime)
    }
}
