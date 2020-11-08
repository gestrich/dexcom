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
    let trend: Int
    let trendRate: Float?
    
    func displayDateDescription() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatterPrint.dateFormat = "h:mm a"
        return dateFormatterPrint.string(from: displayTime)
    }
    
    func presentableTrend() -> String {
        if trend < 4 {
            return "Rising"
        } else if trend > 4 {
            return "Falling"
        } else {
            return "Steady"
        }
    }
}
