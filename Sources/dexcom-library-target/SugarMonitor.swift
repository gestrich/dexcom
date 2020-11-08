//
//  SugarMonitor.swift
//  
//
//  Created by Bill Gestrich on 11/8/20.
//

import Foundation

public struct SugarMonitor {
    
    let username: String
    let password: String
    let slackURL: URL
    
    let dadID = "U01DB1C23F1"
    let billID = "U01559M7E5U"
    
    public init(username: String, password: String, slackURL: URL) {
        self.username = username
        self.password = password
        self.slackURL = slackURL
    }
    
    public func checkSugar() {
        
        let dexcomAPI = DexcomAPIV0(username: username, password: password)
        
        guard let sessionId = dexcomAPI.getToken() else {
            //Post error to Slack
            postToSlack("Could not login as \(username).", isError: true, includeMentions: true)
            return
        }
        
        guard let egv = dexcomAPI.getEGV(sessionId: sessionId) else {
            //Post error to Slack
            postToSlack("Could not connect to Dexcom. Is it connected to the internet?", isError: true, includeMentions: true)
            return
        }
        
        var includeMentions = false
        var isError = false
        
        if egv.value <= 90 {
            includeMentions = true
            isError = true
        } else if egv.value >= 250 {
            //Post error to Slack
            isError = true
            if egv.trend < 4 || egv.value > 500 {
                includeMentions = true
            }
        }
        
        var message = "\(egv.value) (\(egv.presentableTrend())), "
        
        message += egv.displayDateDescription()
        
        postToSlack(message, isError: isError, includeMentions: includeMentions)
        
    }
    
    
    func postToSlack(_ message: String, isError: Bool, includeMentions: Bool) {
        
        var prefix = ""
        
        if isError {
            prefix = ":no_entry: "
        } else {
            prefix = ":white_check_mark: "
        }
        
        var mentionMessage = ""
        if includeMentions {
            mentionMessage = " cc \(standardMentions())"
        }
        
        Slack(url: slackURL).postAndWait(message: prefix + message + mentionMessage)
        
    }
    
    func standardMentions() -> String {
        return " <@\(billID)> <@\(dadID)>"
    }

    
}
