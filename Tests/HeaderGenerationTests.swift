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
import Teapot

class HeaderGenerationTests: XCTestCase {

    private var testCereal: Cereal {
        guard let cereal = Cereal(words: ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]) else {
            fatalError("failed to create cereal")
        }
        return cereal
    }

    private func compare(valueFor field: HeaderGenerator.HeaderField,
                         inExpectedDictionary expectedDictionary: [String: String],
                         toValueIn receivedDictionary: [String: String],
                         shouldMatch: Bool = true,
                         file: StaticString = #file,
                         line: UInt = #line) {
        let expectedValue = expectedDictionary[field.rawValue]
        let receivedValue = receivedDictionary[field.rawValue]

        if shouldMatch {
            XCTAssertEqual(expectedValue, receivedValue,
                           file: file,
                           line: line)
        } else {
            XCTAssertNotEqual(expectedValue, receivedValue,
                              file: file,
                              line: line)
        }
    }

    func testGeneratingGETHeaders() {
        let timestamp = "12345"
        let path = "/v1/get"

        let expectedHeaders = [
            HeaderGenerator.HeaderField.timestamp.rawValue: timestamp,
            HeaderGenerator.HeaderField.address.rawValue: "0xa391af6a522436f335b7c6486640153641847ea2",
            HeaderGenerator.HeaderField.signature.rawValue: "0x56c855458b2ad3be7f3ffe3ee4fe6c1bef5a7b7641ac90c55d5e507369bfc45312236498df05f346fe334769e7a3903a514ae4c30751056eab1f54672937a81201"
        ]

        let generatedHeaders = HeaderGenerator.createGetSignatureHeaders(path: path, cereal: testCereal, timestamp: timestamp)

        XCTAssertEqual(generatedHeaders, expectedHeaders)

        // If you change the path, the signature should change, but the address and timestamp should be the same
        let otherHeaders = HeaderGenerator.createGetSignatureHeaders(path: "/something/else/", cereal: testCereal, timestamp: timestamp)
        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: otherHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: otherHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: otherHeaders,
                shouldMatch: false)
    }

    func testGeneratingHeadersFromDictionary() {
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

        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: pathChangedHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: pathChangedHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: pathChangedHeaders,
                shouldMatch: false)

        // Changing just the payload should create a different signature
        let changedPayloadHeaders: [String: String]
        do {
            changedPayloadHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: path, cereal: testCereal, payloadDictionary: [ "foo": "baz" ])
        } catch let error {
            XCTFail("Error creating changed payload headers: \(error)")
            return
        }

        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedPayloadHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedPayloadHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedPayloadHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: pathChangedHeaders,
                toValueIn: changedPayloadHeaders,
                shouldMatch: false)

        // Changing just the method should change the signature
        let changedMethodHeaders: [String: String]
        do {
            changedMethodHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: path, method: .PUT, cereal: testCereal, payloadDictionary: testDictionary)
        } catch let error {
            XCTFail("Error creating headers from dictionary: \(error)")
            return
        }

        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: changedPayloadHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: pathChangedHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)

    }

    func testGeneratingHeadersFromData() {
        let path = "/v1/profile/photo"
        let timestamp = "33333"

        guard let testData = "{\"foo\":\"bar\"}".data(using: .utf8) else {
            XCTFail("Could not encode data with UTF8")
            return
        }

        let dataGeneratedHeaders: [String: String]
        do {
            dataGeneratedHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: path, cereal: testCereal, payloadData: testData)
        } catch let error {
            XCTFail("Error creating headers from data: \(error)")
            return
        }

        let expectedHeaders = [
            HeaderGenerator.HeaderField.timestamp.rawValue: timestamp,
            HeaderGenerator.HeaderField.address.rawValue: "0xa391af6a522436f335b7c6486640153641847ea2",
            HeaderGenerator.HeaderField.signature.rawValue: "0xdb5e81881f93ae208d10aa65c880f3d27f224d4d696cc842f1112ccea2ec1f412db6733e72831461ca47066e56f64e2c00ceaef50e4f2097dbcedfa99c40c80500"
        ]

        XCTAssertEqual(dataGeneratedHeaders, expectedHeaders)

        // Changing just the path should create a different signature
        let pathChangedHeaders: [String: String]
        do {
            pathChangedHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: (path + "/"), cereal: testCereal, payloadData: testData)
        } catch let error {
            XCTFail("Error creating path changed headers from dictionary: \(error)")
            return
        }

        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: pathChangedHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: pathChangedHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: pathChangedHeaders,
                shouldMatch: false)

        // Changing just the payload should create a different signature
        let changedPayloadHeaders: [String: String]
        do {
            changedPayloadHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: path, cereal: testCereal, payloadDictionary: [ "foo": "baz" ])
        } catch let error {
            XCTFail("Error creating changed payload headers: \(error)")
            return
        }

        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedPayloadHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedPayloadHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedPayloadHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: pathChangedHeaders,
                toValueIn: changedPayloadHeaders,
                shouldMatch: false)

        // Changing just the method should change the signature
        let changedMethodHeaders: [String: String]
        do {
            changedMethodHeaders = try HeaderGenerator.createHeaders(timestamp: timestamp, path: path, method: .PUT, cereal: testCereal, payloadData: testData)
        } catch let error {
            XCTFail("Error creating headers from dictionary: \(error)")
            return
        }

        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: changedPayloadHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: pathChangedHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)
    }

    func testGeneratingHeadersFromMultipartFormData() {
        let image = ImageAsset.checkmark_big

        let timestamp = "222035213"
        let path = "/v2/user"
        let boundary = "boundary1"
        let fileName = "avatar.png"
        let teapot = MockTeapot(bundle: Bundle(for: HeaderGenerationTests.self), mockFilename: "")
        let testPayload = teapot.multipartData(from: image, boundary: boundary, filename: fileName)

        let multipartHeaders = HeaderGenerator.createMultipartHeaders(boundary: boundary,
                                                                      path: path,
                                                                      timestamp: timestamp,
                                                                      payload: testPayload,
                                                                      cereal: testCereal)

        let expectedHeaders = [
            HeaderGenerator.HeaderField.timestamp.rawValue: timestamp,
            HeaderGenerator.HeaderField.address.rawValue: "0xa391af6a522436f335b7c6486640153641847ea2",
            HeaderGenerator.HeaderField.signature.rawValue: "0x9d1e2f99303937593419bc9bc6ed0c6f51890ed9b8dcc5b21c4e5740f4eeb74a3310945cb642c76eb55b8a8c36d145efb07b7d575caa1af5905e66dc62c6a13601",
            HeaderGenerator.HeaderField.contentType.rawValue: "multipart/form-data; boundary=\(boundary)",
            HeaderGenerator.HeaderField.contentLength.rawValue: "802"
        ]

        XCTAssertEqual(multipartHeaders, expectedHeaders)
        
        // Changing just the boundary should change the content type but not the signature or length
        let changedBoundaryHeaders = HeaderGenerator.createMultipartHeaders(boundary: "boundary_longer",
                                                                            path: path,
                                                                            timestamp: timestamp,
                                                                            payload: testPayload,
                                                                            cereal: testCereal)

        compare(valueFor: .timestamp,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedBoundaryHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedBoundaryHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedBoundaryHeaders)

        compare(valueFor: .contentType,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedBoundaryHeaders,
                shouldMatch: false)

        compare(valueFor: .contentLength,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedBoundaryHeaders)

        // Changing just the path should create a different signature but leave content and length type alone
        let changedPathHeaders = HeaderGenerator.createMultipartHeaders(boundary: boundary,
                                                                        path: path + "/",
                                                                        timestamp: timestamp,
                                                                        payload: testPayload,
                                                                        cereal: testCereal)
        compare(valueFor: .timestamp,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedPathHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedPathHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedPathHeaders,
                shouldMatch: false)

        compare(valueFor: .contentType,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedPathHeaders)

        compare(valueFor: .contentLength,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedPathHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: changedBoundaryHeaders,
                toValueIn: changedPathHeaders,
                shouldMatch: false)

        // Changing just the image should the signature and length but not the content type
        let otherImage = ImageAsset.checkmark
        let testPayloadWithOtherImage = teapot.multipartData(from: otherImage, boundary: boundary, filename: fileName)
        XCTAssertNotEqual(testPayload, testPayloadWithOtherImage)

        let changedImageHeaders = HeaderGenerator.createMultipartHeaders(boundary: boundary,
                                                                         path: path,
                                                                         timestamp: timestamp,
                                                                         payload: testPayloadWithOtherImage,
                                                                         cereal: testCereal)

        compare(valueFor: .timestamp,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedImageHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedImageHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedImageHeaders,
                shouldMatch: false)

        compare(valueFor: .contentType,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedImageHeaders)

        compare(valueFor: .contentLength,
                inExpectedDictionary: multipartHeaders,
                toValueIn: changedImageHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: changedBoundaryHeaders,
                toValueIn: changedImageHeaders,
                shouldMatch: false)

        // Changing just the method should change the signature
        let changedMethodHeaders = HeaderGenerator.createMultipartHeaders(boundary: boundary,
                                                                          path: path,
                                                                          timestamp: timestamp,
                                                                          payload: testPayload,
                                                                          method: .PUT,
                                                                          cereal: testCereal)

        compare(valueFor: .timestamp,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .address,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .contentType,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .contentLength,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders)

        compare(valueFor: .signature,
                inExpectedDictionary: expectedHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: changedImageHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)

        compare(valueFor: .signature,
                inExpectedDictionary: changedPathHeaders,
                toValueIn: changedMethodHeaders,
                shouldMatch: false)
    }

}
