//
//  EGVJSONV2.swift
//  
//
//  Created by Bill Gestrich on 11/1/20.
//

import Foundation

struct EGVJSONV2: Codable {
    let value: Int
    let systemTime: Date
    let displayTime: Date
    let realtimeValue: Int
    let smoothedValue: Int?
    
    /*
     3..8: singleUp
     2..<3: fortyFiveUp
     1..<2: flat
     -2..-1: fortyFiveDown
     -3..-2: singleDown
     -8..3: doubleDown
     */
    let trend: String
    let trendRate: Float?
    
}

struct EGVSJSONResult: Codable {
    let unit: String
    let rateUnit: String
    let egvs: [EGVJSONV2]
}

extension EGVJSONV2 {
    
    func toEGV() -> EGV {
        
        return EGV(value: value, systemTime: systemTime, displayTime: displayTime, realtimeValue: realtimeValue, smoothedValue: nil, trendRate: trendRate, trendDescription: trend)
    }
}


