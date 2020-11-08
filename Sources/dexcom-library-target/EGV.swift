//
//  EGV.swift
//  
//
//  Created by Bill Gestrich on 11/8/20.
//

import Foundation

public struct EGV {
    public let value: Int
    public let systemTime: Date
    public let displayTime: Date
    public let realtimeValue: Int?
    public let smoothedValue: Int?
    public let trendRate: Float?
    public let trendDescription: String
    
    public init(value: Int, systemTime: Date, displayTime: Date, realtimeValue: Int?, smoothedValue: Int?, trendRate: Float?, trendDescription: String){
        self.value = value
        self.systemTime = systemTime
        self.displayTime = displayTime
        self.realtimeValue = realtimeValue
        self.smoothedValue = smoothedValue
        self.trendRate = trendRate
        self.trendDescription = trendDescription
    }
    
    public var debugDescription: String {
        return "\(displayTime): \(value), (\(trendDescription) \(trendRate ?? 0.0))"
    }
    
    public func simpleDescription() ->  String {
        return "\(value) (\(trendDescription) \(trendRate ?? 0.0))"
    }
    
    public func displayDateDescription() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatterPrint.dateFormat = "h:mm a"
        return dateFormatterPrint.string(from: displayTime)
    }
}
