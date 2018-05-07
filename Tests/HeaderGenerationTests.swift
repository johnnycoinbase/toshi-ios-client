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

@testable import Toshi
import XCTest

class HeaderGenerationTests: XCTestCase {

    private var testCereal: Cereal {
        guard let cereal = Cereal(words: ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]) else {
            fatalError("failed to create cereal")
        }
        return cereal
    }

    func testGeneratingGETHeaders() {
        let timestamp = "12345"
        let path = "/v1/get"

        let expectedHeaders = [
            HeaderGenerator.HeaderField.timestamp.rawValue: timestamp,
            HeaderGenerator.HeaderField.address.rawValue: "0xa391af6a522436f335b7c6486640153641847ea2",
            HeaderGenerator.HeaderField.signature.rawValue: "0x9098476693a6e7b24a722296138c9032388beea043d8b7e8ca30f21fdd79ca2c19c47d9e6acf4dec7dfc5f09f7003470b26a23035c68ccd10ba1a3b7e924fb1a00"
        ]

        let generatedHeaders = HeaderGenerator.createGetSignatureHeaders(path: path, cereal: testCereal, timestamp: timestamp)

        XCTAssertEqual(generatedHeaders, expectedHeaders)

        // If you change the path, the signature should change, but the address and timestamp should be the same
        let otherHeaders = HeaderGenerator.createGetSignatureHeaders(path: "/something/else/", cereal: testCereal, timestamp: timestamp)
        XCTAssertEqual(otherHeaders[HeaderGenerator.HeaderField.timestamp.rawValue],
                       generatedHeaders[HeaderGenerator.HeaderField.timestamp.rawValue])
        XCTAssertEqual(otherHeaders[HeaderGenerator.HeaderField.address.rawValue],
                       generatedHeaders[HeaderGenerator.HeaderField.address.rawValue])
        XCTAssertNotEqual(otherHeaders[HeaderGenerator.HeaderField.signature.rawValue],
                          generatedHeaders[HeaderGenerator.HeaderField.signature.rawValue])
    }

    func testGeneratingPOSTHeadersFromDictionary() {
        let path = "/v1/profile"
        let timestamp = "44444444"

        let testDictionary = [ "foo": "bar" ]

        let dictionaryGeneratedHeaders: [String: String]
        do {
            dictionaryGeneratedHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: path, cereal: testCereal, payloadDictionary: testDictionary)
        } catch let error {
            XCTFail("Error creating headers from dictionary: \(error)")
            return
        }

        let expectedHeaders = [
            HeaderGenerator.HeaderField.timestamp.rawValue: timestamp,
            HeaderGenerator.HeaderField.address.rawValue: "0xa391af6a522436f335b7c6486640153641847ea2",
            HeaderGenerator.HeaderField.signature.rawValue: "0xea4780cd5f72dea31826d6ed44cdafc9b867165742a67d990abc8132d6c8678e5671fd78d2e4e53dbc8b49916e09be52a3c3e826253242d9b6810596bf76012300"
        ]

        XCTAssertEqual(dictionaryGeneratedHeaders, expectedHeaders)

        // Changing just the path should create a different signature
        let pathChangedHeaders: [String: String]
        do {
            pathChangedHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: (path + "/"), cereal: testCereal, payloadDictionary: testDictionary)
        } catch let error {
            XCTFail("Error creating path changed headers from dictionary: \(error)")
            return
        }

        XCTAssertEqual(pathChangedHeaders[HeaderGenerator.HeaderField.timestamp.rawValue],
                       dictionaryGeneratedHeaders[HeaderGenerator.HeaderField.timestamp.rawValue])
        XCTAssertEqual(pathChangedHeaders[HeaderGenerator.HeaderField.address.rawValue],
                       dictionaryGeneratedHeaders[HeaderGenerator.HeaderField.address.rawValue])
        XCTAssertNotEqual(pathChangedHeaders[HeaderGenerator.HeaderField.signature.rawValue],
                          dictionaryGeneratedHeaders[HeaderGenerator.HeaderField.signature.rawValue])

        // Changing just the payload should create a different signature
        let changedPayloadHeaders: [String: String]
        do {
            changedPayloadHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: path, cereal: testCereal, payloadDictionary: [ "foo": "baz" ])
        } catch let error {
            XCTFail("Error creating changed payload headers: \(error)")
            return
        }

        XCTAssertEqual(changedPayloadHeaders[HeaderGenerator.HeaderField.timestamp.rawValue],
                       dictionaryGeneratedHeaders[HeaderGenerator.HeaderField.timestamp.rawValue])
        XCTAssertEqual(changedPayloadHeaders[HeaderGenerator.HeaderField.address.rawValue],
                       dictionaryGeneratedHeaders[HeaderGenerator.HeaderField.address.rawValue])
        XCTAssertNotEqual(changedPayloadHeaders[HeaderGenerator.HeaderField.signature.rawValue],
                          dictionaryGeneratedHeaders[HeaderGenerator.HeaderField.signature.rawValue])
        XCTAssertNotEqual(changedPayloadHeaders[HeaderGenerator.HeaderField.signature.rawValue],
                          pathChangedHeaders[HeaderGenerator.HeaderField.signature.rawValue])

    }

}
