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
import EtherealCereal

enum HeaderGenerationError: Error {
    case
    /// The data provided could not be transformed into a string for hashing and signing.
    couldNotCreatePayloadString,
    
    /// The dictionary provided could not be serialized
    couldNotSerializePayloadDictionary
}

struct HeaderGenerator {

    private static var testingCereal: Cereal?
    static func defaultCereal() -> Cereal {
        guard testingCereal == nil else {
            return testingCereal!
        }
        return Cereal.shared
    }

    static func setTestingCereal(_ cereal: Cereal) {
        testingCereal = cereal
    }

    static func clearTestingCereal() {
        testingCereal = nil
    
    }

    enum HTTPMethod: String {
        case
        GET,
        PUT,
        POST
    }

    enum HeaderField: String {
        case
        address = "Toshi-ID-Address",
        contentLength = "Content-Length",
        contentType = "Content-Type",
        signature = "Toshi-Signature",
        timestamp = "Toshi-Timestamp"

        static func headers(address: String, signature: String, timestamp: String) -> [String: String] {
            return [
                self.address.rawValue: address,
                self.signature.rawValue: signature,
                self.timestamp.rawValue: timestamp
            ]
        }
    }

    /// Creates signed headers from a Dictionary.
    ///
    /// - Parameters:
    ///   - timestamp: The timestamp to use when creating a header
    ///   - path: The path you're sending this data to
    ///   - method: The `HTTPMethod` you're using to send this data. Defaults to `POST`.
    ///   - cereal: The cereal to use for signing. Defaults to the shared Cereal.
    ///   - payloadDictionary: The dictionary of data being sent to the server.
    /// - Returns: A dictionary of string keys and string values which can be passed through as headers.
    /// - Throws: see `HeaderGenerationError`
    static func createHeaders(timestamp: String,
                              path: String,
                              method: HTTPMethod = .POST,
                              cereal: Cereal = defaultCereal(),
                              payloadDictionary: [String: Any]) throws -> [String: String] {
        guard let data = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []) else {
            throw HeaderGenerationError.couldNotSerializePayloadDictionary
        }

        return try createHeaders(timestamp: timestamp,
                             path: path,
                             method: method,
                             cereal: cereal,
                             payloadData: data)
    }

    /// Creates signed headers from serialized JSON Data.
    ///
    /// - Parameters:
    ///   - timestamp: The timestamp to use when creating a header
    ///   - path: The path you're sending this data to
    ///   - method: The `HTTPMethod` you're using to send this data. Defaults to `POST`
    ///   - cereal: The cereal to use for signing. Defaults to the shared Cereal.
    ///   - payloadData: The JSON data being sent to the server.
    /// - Returns: A dictionary of string keys and string values which can be passed through as headers.
    /// - Throws: see `HeaderGenerationError`
    static func createHeaders(timestamp: String,
                              path: String,
                              method: HTTPMethod = .POST,
                              cereal: Cereal = defaultCereal(),
                              payloadData: Data) throws -> [String: String] {

        guard let payloadString = String(data: payloadData, encoding: .utf8) else {
            throw HeaderGenerationError.couldNotCreatePayloadString
        }

        return createHeaders(payloadString: payloadString,
                             path: path,
                             method: method,
                             timestamp: timestamp,
                             cereal: cereal)
    }

    private static func createHeaders(payloadString: String,
                                      path: String,
                                      method: HTTPMethod,
                                      timestamp: String,
                                      cereal: Cereal) -> [String: String] {

        let hashedPayload = cereal.sha3WithID(string: payloadString)
        let message = "\(method.rawValue)\n\(path)\n\(timestamp)\n\(hashedPayload)"
        let signature = "0x\(cereal.signWithID(message: message))"

        return HeaderField.headers(address: cereal.address,
                                   signature: signature,
                                   timestamp: timestamp)
    }

    /// Creates headers for requests uploading multipart data.
    ///
    /// - Parameters:
    ///   - boundary: The boundary string between the parts of the data.
    ///   - path: The path the data is being uploaded to
    ///   - timestamp: The timestamp to use when creating a header
    ///   - payload: The data being sent as multipart data (with boundaries already included)
    ///   - method: The HTTPMethod being used to send the data. Defaults to `.POST`
    ///   - cereal: The cereal to use for signing. Defaults to the shared Cereal.
    /// - Returns: The headers for your multipart request.
    static func createMultipartHeaders(boundary: String,
                                       path: String,
                                       timestamp: String,
                                       payload: Data,
                                       method: HTTPMethod = .POST,
                                       cereal: Cereal = defaultCereal()) -> [String: String] {
        let hashedPayload = cereal.sha3WithID(data: payload)
        let signature = "0x\(cereal.signWithID(message: "\(method.rawValue)\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

        var headers = HeaderField.headers(address: cereal.address,
                                          signature: signature,
                                          timestamp: timestamp)
        headers[HeaderField.contentLength.rawValue] = String(describing: payload.count)
        headers[HeaderField.contentType.rawValue] = "multipart/form-data; boundary=\(boundary)"

        return headers
    }

    /// Creates a simple signature header for a GET request
    ///
    /// - Parameters:
    ///   - path: The path you're requesting the GET from
    ///   - cereal: The cereal to use for signing. Defaults to the shared cereal.
    ///   - timestamp: The timestamp to use when creating a header
    /// - Returns: A dictionary of string keys and string values which can be passed through as headers.
    static func createGetSignatureHeaders(path: String,
                                          cereal: Cereal = defaultCereal(),
                                          timestamp: String) -> [String: String] {
        let signature = "0x\(cereal.signWithID(message: "\(HTTPMethod.GET.rawValue)\n\(path)\n\(timestamp)\n"))"

        return HeaderField.headers(address: cereal.address,
                                   signature: signature,
                                   timestamp: timestamp)
    }
}
