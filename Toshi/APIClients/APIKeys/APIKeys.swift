// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

struct APIKeys {
    
    static let Fabric = "Fabric_API_Key"
    static let AmplitudeProduction = "AmplitudeProduction"
    static let AmplitudeDevelopment = "AmplitudeDevelopment"
    
    static func key(named keyname: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: "APIKeys", ofType: "plist", inDirectory: "APIKeys"),
            let plist = NSDictionary(contentsOfFile: filePath),
            let value = plist.object(forKey: keyname) as? String else {
                DLog("Can't load API Keys plist file")
                return nil
        }
        
        return value
    }
}

final class APIKeysManager {
    
    /**
     The keys are stored in a separate plist file that isn't included in this project so
     we need to check for the existence of the file before we can initialize these services.
     */
    static func setup() {
        if let fabricKey = APIKeys.key(named: APIKeys.Fabric) {
            CrashlyticsClient.start(with: fabricKey)
        } else {
            DLog("Can't load Fabric API Key")
        }
        
        let amplitudeEnvironment = Bundle.main.bundleIdentifier == "org.toshi.distribution" ?
            APIKeys.AmplitudeProduction : APIKeys.AmplitudeDevelopment
        if let amplitudeAPIKey = APIKeys.key(named: amplitudeEnvironment) {
            Amplitude.instance().initializeApiKey(amplitudeAPIKey)
        } else {
            DLog("Can't load Amplitude API Key")
        }
        
    }
}
