//
//  DexcomAPI.swift
//  
//
//  Created by Bill Gestrich on 11/1/20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import swift_utilities

/*
 API Docs: https://developer.dexcom.com/overview
 */

public class DexcomAPIV2: RestClient {
    
    let tokenPath = "/Users/bill/dev/personal/dexcom/token.json"
    let clientID = "XB9WKlpkNZZW8Z4pXSJVOn9fdqLrzcID"
    let clientSecret = "Z5U92b5HuBeAbMnC"
    let code = "3ef6490fa1ae292921936a4a398165ed"
    let redirectURI = "http://localhost:8080/authorization-code/callback"
    let url = "https://api.dexcom.com/v2/oauth2/token"
    
    override public init(baseURL: String) {
        super.init(baseURL: baseURL)
        guard let token = self.refreshToken() else {
            fatalError()
        }
        self.headers =  ["authorization": "Bearer \(token.access_token)"]
    }
    
    public func authorizationURL() -> String {
        return "https://api.dexcom.com/v2/oauth2/login?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code&scope=offline_access"
    }
    
    /*
     Real Time Values:
     
     curl -v \
       -H "Accept: application/json" -H "Content-Type: application/json" \
       -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0" \
       -X POST https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName \
       -d '{"accountName":"<account-name>","applicationId":"d8665ade-9673-4e27-9ff6-92db4ce13d13","password":"pw"}'
     
     curl -v \
       -H "Content-Length: 0" -H "Accept: application/json" \
       -H "User-Agent: Dexcom Share/3.0.2.11 CFNetwork/672.0.2 Darwin/14.0.0" \
       -X POST "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId=025dabca-21f8-40ff-9c29-39f8a2317bb1&minutes=10&maxCount=1"
     */
    
    public func getEGVS() {
        /*
         * TODO: Use now date here.
         */
        let result = synchronousData(relativeURL: "egvs?startDate=2020-11-08T00:00:00&endDate=2020-12-08T15:45:00") { (json) in
            let decoder = self.jsonDecoder()
            do {
                let result = try decoder.decode(EGVSJSONResult.self, from: json)
                let egvs = result.egvs.map { (egvJSON) -> EGV in
                    return egvJSON.toEGV()
                }
                
                let sortedEGVS = egvs.sorted(by: {$0.displayTime < $1.displayTime})
                for egvs in sortedEGVS {
                    print("\(egvs.value): \(egvs.displayTime)")
                }
                
                let lastReadings = sortedEGVS.suffix(1000)
                
                let message = lastReadings.reduce("") { (partialMessage, egv) -> String in
                    return partialMessage.appending("\(egv.debugDescription)\n")
                }
                
                print(message)

            } catch (let deserializationErorr){
                //errorBlock(.deserialization(error))
                print("deserialization error \(deserializationErorr)")
            }
            print(json)
        } errorBlock: { (error) in
            print(error)
        }
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
    
    func refreshToken() -> Token? {
        if let existingToken = self.getExistingToken() {
            if let token = self.getToken(authorizationCode: nil, refreshToken: existingToken.refresh_token) {
                self.saveToken(token)
                return token
            }
        }
        
        return nil
    }
    
    //TODO: This requires a code to be requested which only last a minute before this is called.
    func getToken(authorizationCode: String?, refreshToken: String?) -> Token? {
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded",
            "cache-control": "no-cache",
            "Accept": "application/json"
        ]
        
        var dataString = "client_secret=\(clientSecret)&client_id=\(clientID)&redirect_uri=\(redirectURI)"
        
        if let authorizatinCode = authorizationCode {
            dataString += "&code=\(authorizatinCode)"
            dataString += "&grant_type=authorization_code"
        } else if let refreshToken = refreshToken {
            dataString += "&refresh_token=\(refreshToken)"
            dataString += "&grant_type=refresh_token"
        }
        
        let postData = NSMutableData(data: dataString.data(using: String.Encoding.utf8)!)
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data
        
        let session = URLSession.shared
        
        let semaphore = DispatchSemaphore(value: 0)
        var token: Token?
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse!)
                
                do {
                    let decoder = JSONDecoder()
                    token = try decoder.decode(Token.self, from: data!)
                    //try decoder.decode(Dictionary<String, String>.self, from: data!)
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
    
    func saveToken(_ token: Token) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(token)
            if FileManager.default.fileExists(atPath: tokenPath) {
                try FileManager.default.removeItem(atPath: tokenPath)
            }
            FileManager.default.createFile(atPath: tokenPath, contents: data, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }

        print(token)
    }


    func getExistingToken() -> Token? {
        
        if let data = FileManager.default.contents(atPath: tokenPath) {
            let decoder = JSONDecoder()
            do {
                let token = try decoder.decode(Token.self, from: data)
                return token
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            fatalError("No data at \(tokenPath)!")
        }
    }
    
}
