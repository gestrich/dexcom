import Foundation
import dexcom_library_target

func localCredentials() -> DexcomCredentials? {
    let envPath = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".dexcom.json")

    let decoder = JSONDecoder()
    do {
        let data = try Data(contentsOf: envPath)
        return try decoder.decode(DexcomCredentials.self, from: data)
    } catch {
        print("Could not find credentials at \(envPath)")
    }
    
    return nil
}


let realTime = true

guard let credentials = localCredentials() else {
    fatalError()
}

if realTime {
    let sugarMonitor = SugarMonitor(username: credentials.username, password: credentials.password, slackURL: credentials.slackURL)
    sugarMonitor.checkSugar()

} else {
    let dexcom = DexcomAPIV2.init(baseURL: "https://api.dexcom.com/v2/users/self/")
    print(dexcom.authorizationURL())
    dexcom.getEGVS()
}



