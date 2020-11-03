//
//  DexcomRealTimeAPI.swift
//  
//
//  Created by Bill Gestrich on 11/3/20.
//

import Foundation
import swift_utilities

public class DexcomRealTimeAPI: RestClient {
    
    let egvsPath = "/Users/bill/dev/personal/dexcom/last-egvs.json"
    var username: String
    let password: String
    let slackURL: URL
    let applicationId = "d8665ade-9673-4e27-9ff6-92db4ce13d13"
    
    let dadID = "U01DB1C23F1"
    let billID = "U01559M7E5U"
    
    public init(baseURL: String, username: String, password: String, slackURL: URL) {
        self.username = username
        self.password = password
        self.slackURL = slackURL
        super.init(baseURL: baseURL)
        self.headers =  DexcomRealTimeAPI.headers()
    }
    
    /*
     Real Time Values:
     
     curl -v \
       -H "Content-Length: 0" -H "Accept: application/json" \
       -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/672.0.2 Darwin/14.0.0" \
       -X POST "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId=025dabca-21f8-40ff-9c29-39f8a2317bb1&minutes=10&maxCount=1"
     */
    
    public func checkSugar() {
        guard let sessionId = self.getToken() else {
            //Post error to Slack
            postToSlack("Could not login as \(username).", isError: true, includeMentions: true)
            return
        }
        
        //10 was working, then not. 20 not working
        //sleep(60) //Sleep to allow Dexcom upload to complete (every 5 minutes... :00, :05, :10 )
        
        guard let egvs = self.getEGVS(sessionId: sessionId) else {
            //Post error to Slack
            postToSlack("Could not connect to Dexcom. Is it connected to the internet?", isError: true, includeMentions: true)
            return
        }
        
        var includeMentions = false
        var isError = false
        
        if egvs.Value <= 90 {
            includeMentions = true
            isError = true
        } else if egvs.Value >= 250 {
            //Post error to Slack
            isError = true
            if egvs.Trend < 4 || egvs.Value > 500 {
                includeMentions = true
            }
        }
        
        var message = "\(egvs.Value) (\(egvs.presentableTrend())), "
        
        if let date = egvs.dateTime() {
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatterPrint.dateFormat = "h:mm a"
            message += "" + dateFormatterPrint.string(from: date)
        }
        
        postToSlack(message, isError: isError, includeMentions: includeMentions)
        
    }
    
    func standardMentions() -> String {
        return " <@\(billID)> <@\(dadID)>"
    }
    
    func getEGVS(sessionId: String) -> RealTimeEGVS? {
        
        let headers = ["Accept": "application/json", "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"]
        
        let url = self.fullURLWithRelativeURL(relativeURL: "/Publisher/ReadPublisherLatestGlucoseValues?sessionId=\(sessionId)&minutes=10&maxCount=1")
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 30.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        
        let semaphore = DispatchSemaphore(value: 0)
        var egvs: RealTimeEGVS?
        print(curlRequestWithURL(url: url, headers: headers))
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            } else if let data = data {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse!)
                
                do {
                    egvs = try JSONDecoder().decode([RealTimeEGVS].self, from: data).last
                } catch {
                    print(error)
                }
            }
            
            semaphore.signal()
        })
        
        dataTask.resume()
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return egvs
        
    }
    
    func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        //Hack: When 10:00am local, the date in json is 2020-11-02T07:00:00
        //Maybe it thinks it is in Mountain local?
        //formatter.timeZone = TimeZone(secondsFromGMT: 5*60*60)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        enum DateError: String, Error {
            case invalidDate
        }
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })
        return decoder
    }
    
    /*
    func refreshToken() -> Token? {
        if let existingToken = self.getExistingToken() {
            if let token = self.getToken(authorizationCode: nil, refreshToken: existingToken.refresh_token) {
                self.saveToken(token)
                return token
            }
        }
        
        return nil
    }
     */
    
    //TODO: This requires a code to be requested which only last a minute before this is called.
    func getToken() -> String? {
        
        /*
        curl -v \
          -H "Accept: application/json" -H "Content-Type: application/json" \
          -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0" \
          -X POST https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName \
          -d '{"accountName":"<account-name>","applicationId":"d8665ade-9673-4e27-9ff6-92db4ce13d13","password":"pw"}'
        */
        let headers = DexcomRealTimeAPI.headers()
        
        //var dataString = "accountName=\(username)&applicationId=\(applicationId)&password=\(password)"
        let jsonDictionary = ["accountName": username, "applicationId": applicationId, "password": password]
        
        let data = try! JSONEncoder().encode(jsonDictionary)
        let url = self.fullURLWithRelativeURL(relativeURL: "/General/LoginPublisherAccountByName")
        let postData = NSMutableData(data: data)
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 30.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data
        
        let session = URLSession.shared
        
        let semaphore = DispatchSemaphore(value: 0)
        var token: String?
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse!)
                
                do {
//                    let decoder = JSONDecoder()
                    token = try JSONDecoder().decode(String.self, from: data!)
                } catch {
                    print(error)
                }
                
            }
            
            semaphore.signal()
        })
        
        dataTask.resume()
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return token
    }
 
    
    public func synchronousData(relativeURL: String, completionBlock:@escaping ((Data) -> Void), errorBlock:(@escaping (RestClientError) -> Void)){
            
        let semaphore = DispatchSemaphore(value: 0)

        self.getData(relativeURL: relativeURL, completionBlock: { (data) in
            completionBlock(data)
            semaphore.signal()
        }) { (error) in
            errorBlock(error)
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
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
    
    func saveEGVS(_ egvs: RealTimeEGVS) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(egvs)
            if FileManager.default.fileExists(atPath: egvsPath) {
                try FileManager.default.removeItem(atPath: egvsPath)
            }
            FileManager.default.createFile(atPath: egvsPath, contents: data, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }

        print(egvs)
    }


    func getLastEGVS() -> RealTimeEGVS? {
        
        if let data = FileManager.default.contents(atPath: egvsPath) {
            let decoder = JSONDecoder()
            do {
                let egvs = try decoder.decode(RealTimeEGVS.self, from: data)
                return egvs
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            fatalError("No data at \(egvsPath)!")
        }
    }
    
    static func headers() -> [String: String] {
        return ["Accept": "application/json", "Content-Type": "application/json", "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"]
    }
    
    func curlRequestWithURL (url: String, headers:Dictionary<String, String>) -> String {
        
        //Example output:
        //curl --header "Date: January 10, 2017 14:37:21" -L  <url>
        
        var toRet = "curl "
        
        if headers.count > 0 {
            for (headerKey, headerValue) in headers {
                toRet += "--header "
                toRet += " \"\(headerKey): \(headerValue)\" "
            }
            
            toRet += "-L "
            
            toRet += "\"\(url)\""
        }
        
        return toRet
    }

    
}
