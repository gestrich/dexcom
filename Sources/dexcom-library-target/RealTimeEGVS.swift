//
//  RealTimeEGVS.swift
//  
//
//  Created by Bill Gestrich on 11/3/20.
//

import Foundation

struct RealTimeEGVS: Codable {
    
    /*
     "DT": "/Date(1604424945000+0000)/",
     "ST": "/Date(1604442945000)/",
     "Trend": 3,
     "Value": 296,
     "WT": "/Date(1604442945000)/"
     */
    let DT: String
    let ST: String
    let Trend: Int
    let Value: Int
    let WT: String
    
    func dateTime() -> Date? {
        return dateStringToDate(self.DT)
    }
    
    func systemTime() -> Date? {
        return dateStringToDate(self.ST)
    }
    
    func presentableTrend() -> String {
        if Trend < 4 {
            return "Rising"
        } else if Trend > 4 {
            return "Falling"
        } else {
            return "Steady"
        }
    }
    
    
    func dateStringToDate(_ dateString: String) -> Date? {
        var parsedString = dateString.replacingOccurrences(of: "/Date(", with: "").replacingOccurrences(of: ")/", with: "")
        parsedString = String(parsedString.prefix(10))
        guard let epoch = TimeInterval(parsedString) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: epoch)
    }

}


