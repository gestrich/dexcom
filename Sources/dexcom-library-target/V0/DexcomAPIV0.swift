//
//  DexcomV0API.swift
//  
//
//  Created by Bill Gestrich on 11/3/20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import swift_utilities

/*
 Unofficial API Docs: https://gist.github.com/StephenBlackWasAlreadyTaken/adb0525344bedade1e25
 */

public class DexcomAPIV0: RestClient {
    
    var username: String
    let password: String
    let applicationId = "d8665ade-9673-4e27-9ff6-92db4ce13d13"
    static let baseURLString = "https://share2.dexcom.com/ShareWebServices/Services"
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
        super.init(baseURL: DexcomAPIV0.baseURLString)
        self.headers =  DexcomAPIV0.headers()
    }
    
    func getEGV(sessionId: String) -> EGV? {
        
        let headers = ["Accept": "application/json", "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"]
        
        let url = self.fullURLWithRelativeURL(relativeURL: "/Publisher/ReadPublisherLatestGlucoseValues?sessionId=\(sessionId)&minutes=10&maxCount=1")
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 30.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        
        let semaphore = DispatchSemaphore(value: 0)
        var egvJSON: EGVJSONV0?
        print(curlRequestWithURL(url: url, headers: headers))
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            } else if let data = data {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse!)
                
                do {
                    egvJSON = try JSONDecoder().decode([EGVJSONV0].self, from: data).last
                } catch {
                    print(error)
                }
            }
            
            semaphore.signal()
        })
        
        dataTask.resume()
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return egvJSON?.toEGV()
        
    }
    
    
    //TODO: This requires a code to be requested which only last a minute before this is called.
    func getToken() -> String? {
        
        let headers = DexcomAPIV0.headers()
        
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


/*
 
================
 Get Token
===============
curl -v \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0" \
  -X POST https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName \
  -d '{"accountName":"<account-name>","applicationId":"d8665ade-9673-4e27-9ff6-92db4ce13d13","password":"pw"}'


================
Get EGV
===============
 
 curl -v \
   -H "Content-Length: 0" -H "Accept: application/json" \
   -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/672.0.2 Darwin/14.0.0" \
   -X POST "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId=<sessionid>&minutes=10&maxCount=1"
 

 ================
 Turn on monitoring session
 ===============
 
 curl \
        -H "Content-Length: 0" -H "Accept: application/json" \
        -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/672.0.2 Darwin/14.0.0" \
        -X POST "https://share1.dexcom.com/ShareWebServices/Services/Publisher/StartRemoteMonitoringSession?sessionId=<session-id>"   | jq
 
 ================
 Check session monitoring session status
 ===============
 
 curl       -H "Content-Length: 0" -H "Accept: application/json"       -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/672.0.2 Darwin/14.0.0"       -X POST "https://share1.dexcom.com/ShareWebServices/Services/Publisher/IsRemoteMonitoringSessionActive?sessionId=<session-id>"   | jq
 */


