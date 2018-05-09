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

import XCTest
import UIKit
import Quick
import Nimble
import Teapot
@testable import Toshi

class EthereumAPIClientTests: QuickSpec {
    
    let parameters: [String: Any] = [
        "from": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
        "to": "0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
        "value": "0x330a41d05c8a780a"
    ]

    override func spec() {
        describe("the Ethereum API Client") {
            var subject: EthereumAPIClient!
            guard let testCereal = Cereal(entropy: Cereal.generateEntropy()) else {
                fail("Could not generate test cereal!")
                return
            }
            HeaderGenerator.setTestingCereal(testCereal)

            context("Happy path 😎") {
                it("creates an unsigned transaction") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "createUnsignedTransaction")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.createUnsignedTransaction(parameters: self.parameters) { transaction, error in
                            expect(transaction).toNot(beNil())
                            expect(error).to(beNil())
                            
                            expect(transaction).to(equal("0xf085746f6b658d8504a817c800825208945c156634bc3aed611e71550fb8a54480b480cd3b8718972b8c63638a80748080"))
                            done()
                        }
                    }
                }

                it("fetches the transaction Skeleton") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "transactionSkeleton")
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.transactionSkeleton(for: self.parameters) { skeleton, error in
                            expect(skeleton).toNot(beNil())
                            expect(error).to(beNil())

                            expect(skeleton.gas).to(equal("0x5208"))
                            expect(skeleton.gasPrice).to(equal("0xa02ffee00"))
                            expect(skeleton.transaction).to(equal("0xf085746f6b656e850a02ffee0082520894011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f8712103c5eee63dc80748080"))
                            
                            done()
                        }
                    }
                }

                it("sends a signed transaction") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "sendSignedTransaction")
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil(timeout: 3) { done in
                        let originalTransaction = "0xf085746f6b658d8504a817c800825208945c156634bc3aed611e71550fb8a54480b480cd3b8718972b8c63638a80748080"
                        let transactionSignature = "0x4f80931676670df5b7a919aeaa56ae1d0c2db1792e6e252ee66a30007022200e44f61e710dbd9b24bed46338bed73f21e3a1f28ac791452fde598913867ebbb701"
                        subject.sendSignedTransaction(originalTransaction: originalTransaction, transactionSignature: transactionSignature) { success, transactionHash, error in
                            expect(success).to(beTrue())
                            expect(transactionHash).toNot(beNil())
                            expect(error).to(beNil())
                            
                            expect(transactionHash).to(equal("0xe649f968c44d293128b0fa79a9ccba81ed32d72d34205330aa21a77ab6457ae5"))
                            
                            done()
                        }
                    }
                }

                it("gets the balance") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "getBalance")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.getBalance(address: "0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98") { fetchedBalance, error in
                            expect(fetchedBalance).toNot(beNil())
                            expect(error).to(beNil())
                            
                            expect(fetchedBalance).to(equal(3677824408863012874))
                            
                            done()
                        }
                    }
                }

                it("gets tokens") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "getTokens")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.getTokens(address: testCereal.paymentAddress) { tokens, error in
                            expect(tokens).toNot(beNil())
                            expect(error).to(beNil())

                            let token = tokens.first as? Token
                            expect(token).toNot(beNil())
                            expect(token?.name).to(equal("Alphabet Token"))
                            expect(token?.symbol).to(equal("ABC"))
                            expect(token?.value).to(equal("0x1234567890abcdef"))
                            expect(token?.decimals).to(equal(Int(18)))
                            expect(token?.contractAddress).to(equal("0x0123456789012345678901234567890123456789"))
                            expect(token?.icon).to(equal("https://ethereum.service.toshi.org/token/ABC.png"))

                            done()
                        }
                    }
                }

                it("gets collectibles") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "getCollectibles")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.getCollectibles(address: testCereal.paymentAddress) { collectibles, error in
                            expect(collectibles).toNot(beNil())
                            expect(error).to(beNil())

                            let collectible = collectibles.first as? Collectible
                            expect(collectible).toNot(beNil())
                            expect(collectible?.name).to(equal("Cryptokitties"))
                            expect(collectible?.value).to(equal("0x10"))
                            expect(collectible?.contractAddress).to(equal("0x0123456789012345678901234567890123456789"))
                            expect(collectible?.icon).to(equal("https://www.cryptokitties.co/icons/logo.svg"))

                            done()
                        }
                    }
                }

                it("gets a single collectible") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "getACollectible")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.getCollectible(address: testCereal.paymentAddress, contractAddress: "0xb1690c08e213a35ed9bab7b318de14420fb57d8c") { collectible, error in

                            guard let collectible = collectible else {
                                fail("Collectible is nil")
                                return
                            }

                            expect(error).to(beNil())

                            expect(collectible.name).to(equal("Cryptokitties"))
                            expect(collectible.value).to(equal("0x10"))
                            expect(collectible.contractAddress).to(equal("0x0123456789012345678901234567890123456789"))
                            expect(collectible.icon).to(equal("https://www.cryptokitties.co/icons/logo.svg"))

                            guard let token = collectible.tokens?.first else {
                                fail("No tokens on a collectible")
                                return
                            }

                            expect(token.name).to(equal("Kitten 423423"))
                            expect(token.tokenId).to(equal("abcdef0123456"))
                            expect(token.image).to(equal("https://storage.googleapis.com/ck-kitty-image/0x06012c8cf97bead5deae237070f9587f8e7a266d/467583.svg"))
                            expect(token.description).to(equal("A kitten"))

                            done()
                        }
                    }
                }
            }

            context("⚠ Unauthorized error 🔒") {
                it("creates an unsigned transaction") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "createUnsignedTransaction", statusCode: .unauthorized)
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.createUnsignedTransaction(parameters: self.parameters) { transaction, error in
                            expect(transaction).to(beNil())
                            expect(error).toNot(beNil())
                            
                            expect(error?.description).to(equal("Error creating transaction"))
                            
                            done()
                        }
                    }
                }

                it("fetches the transaction Skeleton") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "transactionSkeleton", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.transactionSkeleton(for: self.parameters) { skeleton, error in
                            expect(skeleton).toNot(beNil())
                            expect(error).toNot(beNil())

                            expect(skeleton.gas).to(beNil())
                            expect(skeleton.gasPrice).to(beNil())
                            expect(skeleton.transaction).to(beNil())
                            
                            done()
                        }
                    }
                }

                it("sends a signed transaction") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "sendSignedTransaction", statusCode: .unauthorized)
                    mockTeapot.overrideEndPoint("timestamp", withFilename: "timestamp")
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil(timeout: 3) { done in
                        let originalTransaction = "0xf085746f6b658d8504a817c800825208945c156634bc3aed611e71550fb8a54480b480cd3b8718972b8c63638a80748080"
                        let transactionSignature = "0x4f80931676670df5b7a919aeaa56ae1d0c2db1792e6e252ee66a30007022200e44f61e710dbd9b24bed46338bed73f21e3a1f28ac791452fde598913867ebbb701"
                        subject.sendSignedTransaction(originalTransaction: originalTransaction, transactionSignature: transactionSignature) { success, transactionHash, error in
                            expect(success).to(beFalse())
                            expect(transactionHash).to(beNil())
                            expect(error).toNot(beNil())

                            expect(error?.description).to(equal("An error occurred: request response status reported an issue. Status code: 401."))
                            
                            done()
                        }
                    }
                }

                it("gets the balance") {
                    let mockTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClientTests.self), mockFilename: "getBalance", statusCode: .unauthorized)
                    subject = EthereumAPIClient(mockTeapot: mockTeapot)

                    waitUntil { done in
                        subject.getBalance(address: "0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98") { number, error in
                            expect(number).to(equal(0))
                            expect(error).toNot(beNil())

                            expect(error?.description).to(equal("An error occurred: request response status reported an issue. Status code: 401."))
                            
                            done()
                        }
                    }
                }
            }
        }
    }
}
