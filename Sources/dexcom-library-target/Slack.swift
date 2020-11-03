//
//  Slack.swift
//  
//
//  Created by Bill Gestrich on 11/3/20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Slack {
    
    let url: URL
    
    func post(message: String, completionBlock:@escaping () -> Void, errorBlock:@escaping () -> Void) {
        let payload = "payload={\"channel\": \"#dexcom\", \"username\": \"bot\", \"icon_emoji\":\":calling:\", \"text\": \"\(message)\"}"
        let data = (payload as NSString).data(using: String.Encoding.utf8.rawValue)
        
        let request = NSMutableURLRequest(url: self.url)
        request.httpMethod = "POST"
        request.httpBody = data
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest){
            (data, response, error) -> Void in
            if let error = error {
                print("error: \(error.localizedDescription)")
                errorBlock()
            }
            else if let data = data {
                
                if let str = String(data: data, encoding: String.Encoding.utf8) {
                    completionBlock()
                    print("\(str)")
                }
                else {
                    print("error")
                }
            }
        }
        task.resume()
    }
    
    func postAndWait(message: String) {
        
        let semaphore = DispatchSemaphore(value: 0)
        post(message: message) {
            semaphore.signal()
        } errorBlock: {
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
    }
}
