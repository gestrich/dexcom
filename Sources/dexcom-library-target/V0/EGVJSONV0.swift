//
//  EGVRealTimeJSONResult.swift
//  
//
//  Created by Bill Gestrich on 11/3/20.
//

import Foundation


public struct EGVJSONV0: Codable {

    public let DT: String
    public let ST: String
    public let Trend: Int
    public let Value: Int
    public let WT: String
    
    func dateStringToDate(_ dateString: String) -> Date? {
        //Format: "/Date(1604442945000)/"
        var parsedString = dateString.replacingOccurrences(of: "/Date(", with: "").replacingOccurrences(of: ")/", with: "")
        parsedString = String(parsedString.prefix(10))
        guard let epoch = TimeInterval(parsedString) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: epoch)
    }
}


extension EGVJSONV0 {
    func toEGV() -> EGV? {
        guard let displayTime = dateStringToDate(DT),
              let systemTime = dateStringToDate(ST)  else {
            return nil
        }
        
        return EGV(value: Value, systemTime: systemTime, displayTime: displayTime, realtimeValue: nil, smoothedValue: nil, trend: Trend, trendRate: nil)
    }
}
