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
import BlockiesSwift

class WalletTests: XCTestCase {

    private lazy var expectedWalletAddresses = {

        return ["0x9858effd232b4033e47d90003d41ec34ecaeda94",
                "0x6fac4d18c912343bf86fa7049364dd4e424ab9c0",
                "0xb6716976a3ebe8d39aceb04372f22ff8e6802d7a",
                "0xf3f50213c1d2e255e4b2bad430f8a38eef8d718e",
                "0x51ca8ff9f1c0a99f88e86b8112ea3237f55374ca",
                "0xa40cfbfc8534ffc84e20a7d8bbc3729b26a35f6f",
                "0xb191a13bfe648b61002f2e2135867015b71816a6",
                "0x593814d3309e2df31d112824f0bb5aa7cb0d7d47",
                "0xb14c391e2bf19e5a26941617ab546fa620a4f163",
                "0x4c1c56443abfe6dd33de31daaf0a6e929dbc4971"]
    }()

    private lazy var testCereal: Cereal = {
        guard let cereal = Cereal(words: ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]) else {
            fatalError("failed to create cereal")
        }
        return cereal
    }()

    override func setUp() {
        Wallet.generate(mnemonic: testCereal.mnemonic)
    }
    
    func testGeneratedWalletsAddresses() {

        for (index, wallet) in Wallet.items.enumerated() {
            let expectedWalletAddress = expectedWalletAddresses[index]
            XCTAssertEqual(expectedWalletAddress, wallet.address)
        }
    }
}
