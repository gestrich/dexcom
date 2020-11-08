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
    let trend: String
    let trendRate: Float?
}

struct EGVSJSONResult: Codable {
    let unit: String
    let rateUnit: String
    let egvs: [EGVJSONV2]
}


